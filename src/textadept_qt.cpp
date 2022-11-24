// Copyright 2022 Mitchell. See LICENSE.
// Qt platform for Textadept.

extern "C" {
#include "textadept.h"

#include "lauxlib.h"
}

#include "textadept_qt.h"

#include "ScintillaEditBase.h"

#include <QWindow>
#include <QCloseEvent>
#include <QTextCodec>
#include <QClipboard>
#include <QStatusBar>
#include <QMenuBar>
#include <QTimer>
#include <QMessageBox>
#include <QInputDialog>
#include <QProgressDialog>
#include <QFileDialog>
#include <QTreeView>
#include <QHeaderView>
#include <QDialogButtonBox>
#include <QStandardItemModel>
#include <QSortFilterProxyModel>
#include <QProcessEnvironment>

static Textadept *ta;

const char *get_platform() { return "QT"; }

const char *get_charset() { return QTextCodec::codecForLocale()->name().data(); }

// Returns a SciObject cast to its Qt equivalent.
static ScintillaEditBase *SCI(SciObject *sci) { return static_cast<ScintillaEditBase *>(sci); }

void new_window(SciObject *(*get_view)(void)) {
  ta = new Textadept;
  ta->ui->editors->addWidget(SCI(get_view())), ta->ui->splitter->addWidget(SCI(command_entry));
  ta->show();
  if (QIcon::hasThemeIcon("textadept"))
    ta->windowHandle()->setIcon(QIcon::fromTheme("textadept")); // must come after show()
}

void set_title(const char *title) { ta->setWindowTitle(title); }
bool is_maximized() { return ta->isMaximized(); }
void set_maximized(bool maximize) { maximize ? ta->showMaximized() : ta->showNormal(); }
void get_size(int *width, int *height) { *width = ta->width(), *height = ta->height(); }
void set_size(int width, int height) { ta->resize(width, height); }

// Event filter for Scintilla views. This avoids the need to subclass ScintillaEditBase.
class EventFilter : public QObject {
public:
  EventFilter(QObject *parent = nullptr) : QObject(parent) {}

protected:
  bool eventFilter(QObject *object, QEvent *event) override {
    // Do not propagate focusOutEvent while the command entry is active and the window loses focus.
    // Otherwise the command entry will auto-hide.
    if (event->type() == QEvent::FocusOut && SCI(object) == SCI(command_entry))
      return static_cast<QFocusEvent *>(event)->reason() == Qt::ActiveWindowFocusReason;

    // Propagate non-keypress events as normal.
    if (event->type() != QEvent::KeyPress) return false;

    auto keyEvent = static_cast<QKeyEvent *>(event);

    // Propagate an Escape keypress up to the window if the find & replace pane is visible.
    // This gives the window the opportunity to hide it.
    if (keyEvent->key() == Qt::Key_Escape && ta->ui->findBox->isVisible() &&
      !SCI(command_entry)->hasFocus())
      return QApplication::sendEvent(ta, event);

      // Allow Textadept the first chance at handling the keypress. Otherwise it is propagated to
      // Scintilla.
#if !__APPLE__
    int ctrlModifier = Qt::ControlModifier, metaModifier = 0;
#else
    int ctrlModifier = Qt::MetaModifier, metaModifier = Qt::ControlModifier;
#endif
    return emit("keypress", LUA_TNUMBER, keyEvent->key(), LUA_TBOOLEAN,
      keyEvent->modifiers() & Qt::ShiftModifier, LUA_TBOOLEAN, keyEvent->modifiers() & ctrlModifier,
      LUA_TBOOLEAN, keyEvent->modifiers() & Qt::AltModifier, LUA_TBOOLEAN,
      keyEvent->modifiers() & metaModifier, -1);
  }
};

SciObject *new_scintilla(void (*notified)(SciObject *, int, SCNotification *, void *)) {
  auto view = new ScintillaEditBase;

  if (notified)
    QObject::connect(
      view, &ScintillaEditBase::notify, view, [notified, view](Scintilla::NotificationData *pscn) {
        notified(view, 0, reinterpret_cast<SCNotification *>(pscn), nullptr);
      });

  static EventFilter filter; // only need one instance for the whole application
  view->installEventFilter(&filter);

  QObject::connect(view, &ScintillaEditBase::buttonPressed, view, [](QMouseEvent *event) {
    if (event->button() == Qt::RightButton) show_context_menu("context_menu", event);
  });

  return view;
}

void focus_view(SciObject *view) { SCI(view)->setFocus(); }

sptr_t SS(SciObject *view, int message, uptr_t wparam, sptr_t lparam) {
  return SCI(view)->send(message, wparam, lparam);
}

void split_view(SciObject *view, SciObject *view2, bool vertical) {
  auto pane = new QSplitter{vertical ? Qt::Horizontal : Qt::Vertical};
  int middle = (vertical ? pane->height() : pane->width()) / 2;
  if (auto parentPane = qobject_cast<QSplitter *>(SCI(view)->parent()); parentPane)
    parentPane->replaceWidget(parentPane->indexOf(SCI(view)), pane);
  else
    SCI(view)->parentWidget()->layout()->replaceWidget(SCI(view), pane);
  pane->addWidget(SCI(view)), pane->addWidget(SCI(view2));
  pane->setSizes(QList<int>{middle, middle});
}

static void remove_views(QSplitter *pane, void (*delete_view)(SciObject *view)) {
  QWidget *child1 = pane->widget(0), *child2 = pane->widget(1);
  auto pane1 = qobject_cast<QSplitter *>(child1);
  pane1 ? remove_views(pane1, delete_view) : delete_view(child1);
  auto pane2 = qobject_cast<QSplitter *>(child2);
  pane2 ? remove_views(pane2, delete_view) : delete_view(child2);
  delete pane;
}

bool unsplit_view(SciObject *view, void (*delete_view)(SciObject *)) {
  auto pane = qobject_cast<QSplitter *>(SCI(view)->parent());
  if (!pane) return false;
  QWidget *other = pane->widget(!pane->indexOf(SCI(view)));
  auto otherPane = qobject_cast<QSplitter *>(other);
  otherPane ? remove_views(otherPane, delete_view) : delete_view(other);
  if (auto parentPane = qobject_cast<QSplitter *>(pane->parentWidget()); parentPane)
    parentPane->replaceWidget(parentPane->indexOf(pane), SCI(view));
  else
    pane->parentWidget()->layout()->replaceWidget(pane, SCI(view));
  return (SCI(focused_view)->setFocus(), true);
}

void delete_scintilla(SciObject *view) { delete SCI(view); }

Pane *get_top_pane() {
  auto pane = static_cast<QWidget *>(focused_view);
  while (qobject_cast<QSplitter *>(pane->parentWidget())) pane = pane->parentWidget();
  return pane;
}

PaneInfo get_pane_info(Pane *pane_) {
  auto pane = qobject_cast<QSplitter *>(static_cast<QWidget *>(pane_));
  PaneInfo info{pane != nullptr, false, pane_, pane_, nullptr, nullptr, 0};
  if (info.is_split)
    info.vertical = pane->orientation() == Qt::Horizontal, info.child1 = pane->widget(0),
    info.child2 = pane->widget(1), info.size = pane->sizes().front();
  return info;
}

PaneInfo get_pane_info_from_view(SciObject *view) { return get_pane_info(SCI(view)->parent()); }

void set_pane_size(Pane *pane_, int size) {
  auto pane = static_cast<QSplitter *>(pane_);
  int max = pane->orientation() == Qt::Horizontal ? pane->width() : pane->height();
  pane->setSizes(QList<int>{size, max - size - pane->handleWidth()});
}

void show_tabs(bool show) { ta->ui->tabFrame->setVisible(show); }

void add_tab() { set_tab(ta->ui->tabbar->addTab("")); }

void set_tab(int index) {
  QSignalBlocker blocker{ta->ui->tabbar};
  ta->ui->tabbar->setCurrentIndex(index);
}

void set_tab_label(int index, const char *text) { ta->ui->tabbar->setTabText(index, text); }

void move_tab(int from, int to) {
  QSignalBlocker blocker{ta->ui->tabbar}; // prevent tabMoved
  ta->ui->tabbar->moveTab(from, to);
}

void remove_tab(int index) { ta->ui->tabbar->removeTab(index); }

const char *get_find_text() {
  static std::string text;
  return (text = ta->ui->findCombo->currentText().toStdString(), text.c_str());
}
const char *get_repl_text() {
  static std::string text;
  return (text = ta->ui->replaceCombo->currentText().toStdString(), text.c_str());
}
void set_find_text(const char *text) { ta->ui->findCombo->setCurrentText(text); }
void set_repl_text(const char *text) { ta->ui->replaceCombo->setCurrentText(text); }
void add_to_find_history(const char *text) { ta->ui->findCombo->addItem(text); }
void add_to_repl_history(const char *text) { ta->ui->replaceCombo->addItem(text); }
void set_entry_font(const char * /*name*/) {}
bool is_checked(FindOption *option) { return static_cast<QCheckBox *>(option)->isChecked(); }
void toggle(FindOption *option, bool on) { static_cast<QCheckBox *>(option)->setChecked(on); }
void set_find_label(const char *text) { ta->ui->findLabel->setText(text); }
void set_repl_label(const char *text) { ta->ui->replaceLabel->setText(text); }
void set_button_label(FindButton *button, const char *text) {
  static_cast<QPushButton *>(button)->setText(text);
}
void set_option_label(FindOption *option, const char *text) {
  static_cast<QCheckBox *>(option)->setText(text);
}
void focus_find() {
  if (!ta->ui->findCombo->hasFocus() && !ta->ui->replaceCombo->hasFocus())
    ta->ui->findBox->show(), ta->ui->findCombo->setFocus(),
      ta->ui->findCombo->lineEdit()->selectAll();
  else
    ta->ui->findBox->hide(), SCI(focused_view)->setFocus();
}
bool is_find_active() { return ta->ui->findBox->isVisible(); }

void focus_command_entry() {
  if (!SCI(command_entry)->isVisible())
    SCI(command_entry)->show(), SCI(command_entry)->setFocus();
  else
    SCI(command_entry)->hide(), SCI(focused_view)->setFocus();
}
bool is_command_entry_active() { return SCI(command_entry)->hasFocus(); }
int get_command_entry_height() { return SCI(command_entry)->height(); }
void set_command_entry_height(int height) {
  SCI(command_entry)->setMinimumHeight(height);
  qobject_cast<QSplitter *>(SCI(command_entry)->parent())->setSizes(QList<int>{ta->height()});
}

void set_statusbar_text(int bar, const char *text) {
  bar ? ta->docStatusBar->setText(text) : ta->statusBar()->showMessage(text);
}

void *read_menu(lua_State *L, int index) {
  auto menu = new QMenu;
  if (lua_getfield(L, index, "title")) menu->setTitle(lua_tostring(L, -1)); // submenu title
  lua_pop(L, 1); // title
  for (size_t i = 1; i <= lua_rawlen(L, index); lua_pop(L, 1), i++) {
    if (lua_rawgeti(L, -1, i) != LUA_TTABLE) continue; // popped on loop
    bool isSubmenu = lua_getfield(L, -1, "title");
    if (lua_pop(L, 1), isSubmenu) {
      auto submenu = static_cast<QMenu *>(read_menu(L, -1));
      menu->addMenu(submenu); // TODO: menu does not take ownership; does this leak?
      continue;
    }
    const char *label = (lua_rawgeti(L, -1, 1), lua_tostring(L, -1));
    if (lua_pop(L, 1), !label) continue;
    // Menu item table is of the form {label, id, key, modifiers}.
    QAction *menuItem = *label ? menu->addAction(label) : menu->addSeparator();
    if (*label && get_int_field(L, -1, 3) > 0) {
      int key = get_int_field(L, -1, 3), modifiers = get_int_field(L, -1, 4), qtModifiers = 0;
      if (modifiers & SCMOD_SHIFT) qtModifiers += Qt::SHIFT;
#if !__APPLE__
      if (modifiers & SCMOD_CTRL) qtModifiers += Qt::CTRL;
#else
      if (modifiers & SCMOD_CTRL) qtModifiers += Qt::META;
      if (modifiers & SCMOD_META) qtModifiers += Qt::CTRL;
#endif
      if (modifiers & SCMOD_ALT) qtModifiers += Qt::ALT;
      menuItem->setShortcut(QKeySequence{qtModifiers + key});
      menuItem->setEnabled(false); // disable because Qt will handle key bindings
    }
    int id = get_int_field(L, -1, 2);
    QObject::connect(
      menuItem, &QAction::triggered, ta, [id]() { emit("menu_clicked", LUA_TNUMBER, id, -1); });
  }
  // Enable menu items prior to showing the menu, and then disable them prior to hiding.
  // When key shortcuts are enabled, Qt handles key bindings, and this interferes with Textadept's
  // key handling.
  QObject::connect(menu, &QMenu::aboutToShow, menu, [menu]() {
    for (QAction *action : menu->actions()) action->setEnabled(true);
  });
  QObject::connect(menu, &QMenu::aboutToHide, menu, [menu]() {
    for (QAction *action : menu->actions()) action->setEnabled(false);
  });
  return menu;
}

void popup_menu(void *menu, void *userdata) {
  static_cast<QMenu *>(menu)->popup(
    userdata ? static_cast<QMouseEvent *>(userdata)->globalPos() : QCursor::pos());
}

void set_menubar(lua_State *L, int index) {
  delete ta->menuBar();
  for (size_t i = 1; i <= lua_rawlen(L, index); lua_pop(L, 1), i++) {
    auto menu = static_cast<QMenu *>(lua_rawgeti(L, index, i), lua_touserdata(L, -1));
    ta->menuBar()->addMenu(menu); // TODO: menubar does not take ownership; does this leak?
  }
  ta->menuBar()->setVisible(lua_rawlen(L, index) > 0);
}

char *get_clipboard_text(int *len) {
  const QString &text = QGuiApplication::clipboard()->text();
  *len = text.size();
  return static_cast<char *>(memcpy(malloc(*len), text.toStdString().c_str(), *len));
}

class TimeoutData {
public:
  TimeoutData(double interval, bool (*f)(int *), int *refs) : timer(new QTimer{ta}) {
    QObject::connect(timer, &QTimer::timeout, ta, [this, f, refs]() {
      if (!f(refs)) delete this;
    });
    timer->setInterval(interval * 1000), timer->start();
  }
  ~TimeoutData() { delete timer; }

private:
  QTimer *timer;
};

bool add_timeout(double interval, bool (*f)(int *), int *refs) {
  return (new TimeoutData{interval, f, refs}, true);
}

void update_ui() { QApplication::sendPostedEvents(), QApplication::processEvents(); }

int message_dialog(DialogOptions opts, lua_State *L) {
  QMessageBox dialog{ta};
  if (opts.title) dialog.setText(opts.title);
  if (opts.text) dialog.setInformativeText(opts.text);
  if (opts.icon && QIcon::hasThemeIcon(opts.icon))
    dialog.setIconPixmap(QIcon::fromTheme(opts.icon).pixmap(
      QApplication::style()->pixelMetric(QStyle::PM_MessageBoxIconSize)));
  if (opts.buttons[2]) dialog.addButton(opts.buttons[2], static_cast<QMessageBox::ButtonRole>(2));
  if (opts.buttons[1]) dialog.addButton(opts.buttons[1], static_cast<QMessageBox::ButtonRole>(1));
  dialog.setDefaultButton(
    dialog.addButton(opts.buttons[0], static_cast<QMessageBox::ButtonRole>(0)));
  for (auto &button : dialog.buttons()) button->setFocusPolicy(Qt::StrongFocus);
  // Note: QMessageBox returns an opaque value from dialog.exec().
  return (dialog.exec(), lua_pushinteger(L, dialog.buttonRole(dialog.clickedButton()) + 1), 1);
}

int input_dialog(DialogOptions opts, lua_State *L) {
  QInputDialog dialog{ta};
  if (opts.title) dialog.setLabelText(opts.title);
  if (opts.text) dialog.setTextValue(opts.text);
  if (opts.buttons[1]) dialog.setCancelButtonText(opts.buttons[1]);
  dialog.setOkButtonText(opts.buttons[0]);
  bool ok = dialog.exec();
  if (!ok && !opts.return_button) return 0;
  lua_pushstring(L, dialog.textValue().toStdString().c_str());
  return !opts.return_button ? 1 : (lua_pushinteger(L, ok ? 1 : 2), 2);
}

// `ui.dialogs.open{...}` or `ui.dialogs.save{...}` Lua function.
static int open_save_dialog(DialogOptions *opts, lua_State *L, bool open) {
  QFileDialog dialog{ta};
  if (opts->title) dialog.setWindowTitle(opts->title);
  if (open)
    dialog.setFileMode(!opts->only_dirs ?
        (opts->multiple ? QFileDialog::ExistingFiles : QFileDialog::ExistingFile) :
        QFileDialog::Directory);
  else
    dialog.setFileMode(QFileDialog::AnyFile), dialog.setAcceptMode(QFileDialog::AcceptSave);
  if (opts->dir) dialog.setDirectory(opts->dir);
  if (opts->file) dialog.selectFile(opts->file);
  if (!dialog.exec()) return 0;
  lua_newtable(L); // note: will be replaced by a single value of opts->multiple is false
  for (int i = 0; i < dialog.selectedFiles().size(); i++)
    lua_pushstring(L, dialog.selectedFiles()[i].toLocal8Bit().data()), lua_rawseti(L, -2, i + 1);
  if (!opts->multiple) lua_rawgeti(L, -1, 1), lua_replace(L, -2); // single value
  return 1;
}

int open_dialog(DialogOptions opts, lua_State *L) { return open_save_dialog(&opts, L, true); }
int save_dialog(DialogOptions opts, lua_State *L) { return open_save_dialog(&opts, L, false); }

// Updates the given progressbar dialog with the given percentage and text.
static void update(double percent, const char *text, void *dialog) {
  if (percent >= 0) static_cast<QProgressDialog *>(dialog)->setValue(percent);
  if (text) static_cast<QProgressDialog *>(dialog)->setLabelText(text);
}

int progress_dialog(
  DialogOptions opts, lua_State *L, bool (*work)(void (*)(double, const char *, void *), void *)) {
  QProgressDialog dialog{opts.text ? opts.text : "", opts.buttons[0], 0, 100};
  dialog.setWindowModality(Qt::WindowModal), dialog.setMinimumDuration(0);
  while (work(update, &dialog))
    if (QApplication::processEvents(), dialog.wasCanceled()) break;
  return dialog.wasCanceled() ? (lua_pushboolean(L, true), 1) : 0;
}

class KeyForwarder : public QObject {
public:
  KeyForwarder(QWidget *target, QObject *parent = nullptr) : QObject(parent), target(target) {}

protected:
  bool eventFilter(QObject *object, QEvent *event) override {
    if (event->type() != QEvent::KeyPress) return false;
    int key = static_cast<QKeyEvent *>(event)->key();
    if (key != Qt::Key_Down && key != Qt::Key_Up && key != Qt::Key_PageDown &&
      key != Qt::Key_PageUp)
      return false;
    return (target->setFocus(), QApplication::sendEvent(target, event),
      static_cast<QWidget *>(object)->setFocus(), true);
  }
  QWidget *target;
};

int list_dialog(DialogOptions opts, lua_State *L) {
  QDialog dialog{ta};
  int window_width, window_height;
  get_size(&window_width, &window_height);
  dialog.resize(window_width - 200, 500);
  auto vbox = new QVBoxLayout{&dialog};
  if (opts.title) vbox->addWidget(new QLabel{opts.title});
  auto lineEdit = new QLineEdit;
  QObject::connect(lineEdit, &QLineEdit::returnPressed, &dialog, &QDialog::accept);
  vbox->addWidget(lineEdit);
  auto treeView = new QTreeView;
  vbox->addWidget(treeView);
  auto buttonBox = new QDialogButtonBox;
  QObject::connect(buttonBox, &QDialogButtonBox::accepted, &dialog, &QDialog::accept);
  QObject::connect(buttonBox, &QDialogButtonBox::rejected, &dialog, &QDialog::reject);
  vbox->addWidget(buttonBox);

  auto myFilter = new KeyForwarder{treeView, &dialog};
  lineEdit->installEventFilter(myFilter);

  int num_columns = opts.columns ? lua_rawlen(L, opts.columns) : 1,
      num_items = lua_rawlen(L, opts.items);
  QStandardItemModel model{num_items / num_columns, num_columns};
  for (int i = 0; i < num_items; i++) {
    const char *item = (lua_rawgeti(L, opts.items, i + 1), lua_tostring(L, -1));
    model.setItem(i / num_columns, i % num_columns, new QStandardItem{QString{item}});
    lua_pop(L, 1); // item
  }
  QSortFilterProxyModel filter;
  filter.setFilterCaseSensitivity(Qt::CaseInsensitive);
  filter.setFilterKeyColumn(opts.search_column - 1);
  filter.setSourceModel(&model);
  treeView->setModel(&filter);

  for (int i = 1; i <= num_columns; i++) {
    const char *header = opts.columns ? (lua_rawgeti(L, opts.columns, i), lua_tostring(L, -1)) : "";
    model.setHorizontalHeaderItem(i - 1, new QStandardItem{QString{header}});
    if (opts.columns) lua_pop(L, 1); // header
  }
  treeView->setHeaderHidden(!opts.columns);
  treeView->header()->resizeSections(QHeaderView::ResizeToContents);
  treeView->setSelectionBehavior(QAbstractItemView::SelectRows);
  treeView->setIndentation(0);

  QItemSelectionModel *selection = treeView->selectionModel();
  if (opts.multiple) treeView->setSelectionMode(QAbstractItemView::ExtendedSelection);

  QObject::connect(
    lineEdit, &QLineEdit::textChanged, &filter, [&filter, &selection](const QString &text) {
      filter.setFilterWildcard(QString{text}.replace(' ', '*'));
      selection->select(filter.index(0, 0), QItemSelectionModel::Select);
    });

  if (opts.text) lineEdit->setText(opts.text);
  selection->select(filter.index(0, 0), QItemSelectionModel::Select);

  int buttonClicked = 2; // cancel/reject by default
  if (opts.buttons[2])
    buttonBox->addButton(opts.buttons[2], static_cast<QDialogButtonBox::ButtonRole>(2));
  if (opts.buttons[1])
    buttonBox->addButton(opts.buttons[1], static_cast<QDialogButtonBox::ButtonRole>(1));
  buttonBox->addButton(opts.buttons[0], static_cast<QDialogButtonBox::ButtonRole>(0));
  QObject::connect(buttonBox, &QDialogButtonBox::clicked, ta,
    [buttonBox, &buttonClicked](
      QAbstractButton *button) { buttonClicked = buttonBox->buttonRole(button) + 1; });

  bool ok = dialog.exec();
  if (!ok && !opts.return_button) return 0;
  lua_newtable(L); // note: will be replaced by a single result if opts.multiple is false
  for (int i = 0; i < selection->selectedIndexes().size(); i++)
    lua_pushinteger(L, filter.mapToSource(selection->selectedIndexes()[i]).row() + 1),
      lua_rawseti(L, -2, i + 1);
  if (!opts.multiple) lua_rawgeti(L, -1, 1), lua_replace(L, -2); // single value
  return !opts.return_button ? 1 : (lua_pushinteger(L, buttonClicked), 2);
}

struct _process { // Note: C++ does not allow `struct Process`
  QProcess *proc;
};
static inline QProcess *PROCESS(Process *p) { return static_cast<struct _process *>(p)->proc; }

bool spawn(lua_State *L, Process *proc, int /*index*/, const char *cmd, const char *cwd, int envi,
  bool monitor_stdout, bool monitor_stderr, const char **error) {
  QStringList args;
  // Construct argv from cmd and envp from envi.
  const char *p = cmd;
  while (*p) {
    while (*p == ' ') p++;
    luaL_Buffer buf;
    luaL_buffinit(L, &buf);
    do {
      const char *s = p;
      while (*p && *p != ' ' && *p != '"' && *p != '\'') p++;
      luaL_addlstring(&buf, s, p - s);
      if (*p == '"' || *p == '\'') {
        s = p + 1;
        for (char q = *p++; *p && (*p != q || *(p - 1) == '\\'); p++) {}
        luaL_addlstring(&buf, s, p - s);
        if (*p == '"' || *p == '\'') p++;
      }
    } while (*p && *p != ' ');
    lua_checkstack(L, 1), luaL_pushresult(&buf), args.append(lua_tostring(L, -1)), lua_pop(L, 1);
  }
  QProcessEnvironment env;
  if (envi)
    for (int i = (lua_pushnil(L), 0); lua_next(L, envi); lua_pop(L, 1), i++) {
      std::string pair = lua_tostring(L, -1);
      env.insert(pair.substr(0, pair.find('=')).c_str(), pair.substr(pair.find('=') + 1).c_str());
    }

  auto qProc = new QProcess;
  qProc->setProgram(args.takeFirst()), qProc->setArguments(args);
  if (cwd) qProc->setWorkingDirectory(cwd);
  qProc->setProcessEnvironment(envi ? env : QProcessEnvironment::systemEnvironment());
  if (monitor_stdout)
    QObject::connect(qProc, &QProcess::readyReadStandardOutput, ta, [proc, qProc]() {
      QByteArray bytes = qProc->readAllStandardOutput();
      process_output(proc, bytes.data(), bytes.size(), true);
    });
  if (monitor_stderr)
    QObject::connect(qProc, &QProcess::readyReadStandardError, ta, [proc, qProc]() {
      QByteArray bytes = qProc->readAllStandardError();
      process_output(proc, bytes.data(), bytes.size(), false);
    });
  QObject::connect(qProc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), ta,
    [proc](int exitCode, QProcess::ExitStatus) { process_exited(proc, exitCode); });
  qProc->start();
  if (!qProc->waitForStarted(500)) return (*error = "process failed to start", false);
  return (static_cast<struct _process *>(proc)->proc = qProc, true);
}

size_t process_size() { return sizeof(struct _process); }

bool is_process_running(Process *proc) { return PROCESS(proc)->state() == QProcess::Running; }

void wait_process(Process *proc) { PROCESS(proc)->waitForFinished(-1); }

char *read_process_output(Process *proc, char option, size_t *len, const char **error, int *code) {
  char *buf;
  QSignalBlocker blocker{PROCESS(proc)}; // prevent readyReadStandardOutput
  if (option == 'n') {
    while (static_cast<size_t>(PROCESS(proc)->bytesAvailable()) < *len)
      PROCESS(proc)->waitForReadyRead(-1);
    *len = PROCESS(proc)->read(buf = static_cast<char *>(malloc(*len)), *len);
    return (*len == 0 ? (*error = nullptr, nullptr) : buf);
  }
  int n;
  char ch;
  luaL_Buffer lbuf;
  luaL_buffinit(lua, &lbuf);
  *len = 0;
  if (!PROCESS(proc)->bytesAvailable()) PROCESS(proc)->waitForReadyRead(-1);
  while ((n = PROCESS(proc)->read(&ch, 1)) > 0) {
    if ((ch != '\r' && ch != '\n') || option == 'L' || option == 'a')
      luaL_addchar(&lbuf, ch), (*len)++;
    if (ch == '\n' && option != 'a') break;
    if (!PROCESS(proc)->bytesAvailable()) PROCESS(proc)->waitForReadyRead(-1);
  }
  luaL_pushresult(&lbuf);
  if (n < 0 && !*len && option != 'a') {
    static std::string err;
    err = PROCESS(proc)->errorString().toStdString();
    return (lua_pop(lua, 1), *error = err.c_str(), *code = QProcess::ReadError, nullptr);
  }
  if (n == 0 && !*len && option != 'a') return (lua_pop(lua, 1), *error = nullptr, nullptr); // EOF
  buf = strcpy(static_cast<char *>(malloc(*len + 1)), lua_tostring(lua, -1));
  return (lua_pop(lua, 1), *error = nullptr, buf); // pop buf
}

void write_process_input(Process *proc, const char *s, size_t len) { PROCESS(proc)->write(s, len); }

void close_process_input(Process *proc) { PROCESS(proc)->closeWriteChannel(); }

void kill_process(Process *proc, int /*signal*/) { PROCESS(proc)->kill(); }

int get_process_exit_status(Process *proc) { return PROCESS(proc)->exitCode(); }

void cleanup_process(Process *proc) {
  QSignalBlocker blocker{PROCESS(proc)}; // prevent finished signal for running processes
  delete PROCESS(proc);
}

void quit() { ta->close(); }

class FindKeypressHandler : public QObject {
public:
  FindKeypressHandler(QObject *parent = nullptr) : QObject(parent) {}

protected:
  bool eventFilter(QObject *target, QEvent *event) override {
    if (event->type() != QEvent::KeyPress) return false;
    auto keyEvent = static_cast<QKeyEvent *>(event);
    if (keyEvent->key() != Qt::Key_Return) return false;
    auto button = (keyEvent->modifiers() & Qt::ShiftModifier) == 0 ?
      (target == ta->ui->findCombo ? ta->ui->findNext : ta->ui->replace) :
      (target == ta->ui->findCombo ? ta->ui->findPrevious : ta->ui->replaceAll);
    return (find_clicked(button), true);
  }
};

Textadept::Textadept(QWidget *parent) : QMainWindow(parent), ui(new Ui::Textadept) {
  ui->setupUi(this);

  connect(ui->tabbar, &QTabBar::tabBarClicked, this, [](int index) {
    Qt::MouseButtons button = QApplication::mouseButtons();
    Qt::KeyboardModifiers mods = QApplication::keyboardModifiers();
#if !__APPLE__
    int ctrlModifier = Qt::ControlModifier, metaModifier = 0;
#else
        int ctrlModifier = Qt::MetaModifier, metaModifier = Qt::ControlModifier;
#endif
    emit("tab_clicked", LUA_TNUMBER, index + 1, LUA_TNUMBER, button, LUA_TBOOLEAN,
      mods & Qt::ShiftModifier, LUA_TBOOLEAN, mods & ctrlModifier, LUA_TBOOLEAN,
      mods & Qt::AltModifier, LUA_TBOOLEAN, mods & metaModifier, -1);
    if (button == Qt::RightButton) show_context_menu("tab_context_menu", nullptr);
  });
  connect(ui->tabbar, &QTabBar::currentChanged, this,
    [](int index) { emit("tab_clicked", LUA_TNUMBER, index + 1, -1); });
  connect(ui->tabbar, &QTabBar::tabMoved, this,
    [](int from, int to) { move_buffer(from + 1, to + 1, false); });
  connect(ui->tabbar, &QTabBar::tabCloseRequested, this,
    [](int index) { emit("tab_close_clicked", LUA_TNUMBER, index + 1, -1); });

  auto findKeypressHandler = new FindKeypressHandler{this};
  ui->findCombo->installEventFilter(findKeypressHandler);
  ui->replaceCombo->installEventFilter(findKeypressHandler);
  connect(ui->findCombo->lineEdit(), &QLineEdit::textChanged, this,
    []() { emit("find_text_changed", -1); });
  find_next = ui->findNext, find_prev = ui->findPrevious, replace = ui->replace,
  replace_all = ui->replaceAll;
  match_case = ui->matchCase, whole_word = ui->wholeWord, regex = ui->regex, in_files = ui->inFiles;
  // auto clicked = [this]() { find_clicked(QObject::sender()); };
  connect(ui->findNext, &QPushButton::clicked, this, [this]() { find_clicked(ui->findNext); });
  connect(
    ui->findPrevious, &QPushButton::clicked, this, [this]() { find_clicked(ui->findPrevious); });
  connect(ui->replace, &QPushButton::clicked, this, [this]() { find_clicked(ui->replace); });
  connect(ui->replaceAll, &QPushButton::clicked, this, [this]() { find_clicked(ui->replaceAll); });

  statusBar()->addPermanentWidget(docStatusBar = new QLabel);
  ui->tabFrame->hide(), SCI(command_entry)->hide(), ui->findBox->hide();
}

void Textadept::closeEvent(QCloseEvent *ev) {
  if (emit("quit", -1)) ev->ignore();
}

void Textadept::focusInEvent(QFocusEvent * /*ev*/) {
  if (!SCI(command_entry)->hasFocus()) emit("focus", -1);
}

void Textadept::focusOutEvent(QFocusEvent *ev) {
  if (ev->reason() != Qt::FocusReason::PopupFocusReason) emit("unfocus", -1);
}

void Textadept::keyPressEvent(QKeyEvent *ev) {
  if (ev->key() == Qt::Key_Escape && ui->findBox->isVisible() && !SCI(command_entry)->hasFocus())
    ui->findBox->hide(), SCI(focused_view)->setFocus(), ev->ignore();
}

class Application : public QApplication {
public:
  Application(int &argc, char **argv)
      : QApplication(argc, argv), inited(init_textadept(argc, argv)) {
    setApplicationName("Textadept");
    QObject::connect(this, &QApplication::aboutToQuit, this, []() { close_textadept(); });
  }
  ~Application() override {
    if (inited) delete ta;
  }

  bool event(QEvent *event) override {
    if (event->type() != QEvent::FileOpen) return QApplication::event(event);
    emit("appleevent_odoc", LUA_TSTRING,
      static_cast<QFileOpenEvent *>(event)->file().toStdString().c_str(), -1);
    return true;
  }

  int exec() { return inited ? QApplication::exec() : 1; }

private:
  bool inited;
};

int main(int argc, char *argv[]) { return Application{argc, argv}.exec(); }
