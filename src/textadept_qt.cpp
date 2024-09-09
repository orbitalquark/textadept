// Copyright 2022-2024 Mitchell. See LICENSE.
// Qt platform for Textadept.

extern "C" {
#include "textadept.h"

#include "lauxlib.h"
}

#include "textadept_qt.h"

#include "ScintillaEditBase.h"
#include "singleapplication.h"

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
#include <QSessionManager>
#if _WIN32
#include <QStyleFactory>
#include <windows.h> // for GetACP
#endif

// Qt objects.
static Textadept *ta;

const char *get_platform() { return "QT"; }

const char *get_charset() {
#if !_WIN32
	return QTextCodec::codecForLocale()->name().data();
#else
	// Ask Windows for its charset encoding because QTextCodec returns "System", which is not a
	// valid iconv encoding.
	static char codepage[8];
	return (sprintf(codepage, "CP%d", GetACP()), codepage);
#endif
}

// Returns a SciObject cast to its Qt equivalent.
static ScintillaEditBase *SCI(SciObject *sci) { return static_cast<ScintillaEditBase *>(sci); }

void new_window(SciObject *(*get_view)(void)) {
	ta = new Textadept;
	ta->ui->editors->addWidget(SCI(get_view())), ta->ui->splitter->addWidget(SCI(command_entry));
	ta->show();
}

void set_title(const char *title) { ta->setWindowTitle(title); }
bool is_maximized() { return ta->isMaximized(); }
void set_maximized(bool maximize) { maximize ? ta->showMaximized() : ta->showNormal(); }
void get_size(int *width, int *height) { *width = ta->width(), *height = ta->height(); }
void set_size(int width, int height) { ta->resize(width, height); }

// Returns a Scintilla mask for the given Qt key modifier mask.
static int scModMask(const Qt::KeyboardModifiers &mods) {
	return (mods & Qt::ShiftModifier ? SCMOD_SHIFT : 0) |
		(mods & Qt::ControlModifier ? SCMOD_CTRL : 0) | (mods & Qt::AltModifier ? SCMOD_ALT : 0) |
		(mods & Qt::MetaModifier ? SCMOD_META : 0);
}

// Event filter for Scintilla views. This avoids the need to subclass ScintillaEditBase.
class ScintillaEventFilter : public QObject {
public:
	ScintillaEventFilter(QObject *parent = nullptr) : QObject{parent} {}

protected:
	bool eventFilter(QObject *watched, QEvent *event) override {
		// Do not propagate focusOutEvent while the command entry is active and the window loses focus.
		// Otherwise the command entry will auto-hide.
		if (event->type() == QEvent::FocusOut && SCI(watched) == SCI(command_entry))
			return static_cast<QFocusEvent *>(event)->reason() == Qt::ActiveWindowFocusReason;

		// Propagate non-keypress events as normal.
		if (event->type() != QEvent::KeyPress) return false;

		auto keyEvent = static_cast<QKeyEvent *>(event);

		// Propagate an Escape keypress up to the window if the find & replace pane is visible.
		// This gives the window the opportunity to hide that pane.
		if (keyEvent->key() == Qt::Key_Escape && ta->ui->findBox->isVisible() &&
			!SCI(command_entry)->hasFocus())
			return QApplication::sendEvent(ta, event);

		// Allow Textadept the first chance at handling the keypress. Otherwise it is propagated to
		// Scintilla.
		return emit(
			"key", LUA_TNUMBER, keyEvent->key(), LUA_TNUMBER, scModMask(keyEvent->modifiers()), -1);
	}
};

SciObject *new_scintilla(void (*notified)(SciObject *, int, SCNotification *, void *)) {
	auto view = new ScintillaEditBase;
	if (notified)
		QObject::connect(
			view, &ScintillaEditBase::notify, view, [notified, view](Scintilla::NotificationData *pscn) {
				notified(view, 0, reinterpret_cast<SCNotification *>(pscn), nullptr);
			});
	static ScintillaEventFilter filter; // only need one instance for the whole application
	view->installEventFilter(&filter);
	QObject::connect(view, &ScintillaEditBase::buttonPressed, view, [](QMouseEvent *event) {
		if (event->button() == Qt::RightButton) show_context_menu("context_menu", event);
	});
	return view;
}

void focus_view(SciObject *view) {
	if (SCI(view)->setFocus(); SCI(view)->hasFocus()) return;
	// Simulate a FocusIn event so Scintilla sends an SCN_FOCUSIN notification, which emits
	// events and sets focused_view.
	QFocusEvent event{QEvent::FocusIn};
	QApplication::sendEvent(SCI(view), &event);
}

sptr_t SS(SciObject *view, int message, uptr_t wparam, sptr_t lparam) {
	return SCI(view)->send(message, wparam, lparam);
}

void split_view(SciObject *view, SciObject *view2, bool vertical) {
	auto pane = new QSplitter{vertical ? Qt::Horizontal : Qt::Vertical};
	int middle = (vertical ? pane->height() : pane->width()) / 2;
	if (auto parent_pane = qobject_cast<QSplitter *>(SCI(view)->parent()); parent_pane)
		parent_pane->replaceWidget(parent_pane->indexOf(SCI(view)), pane);
	else
		SCI(view)->parentWidget()->layout()->replaceWidget(SCI(view), pane);
	pane->addWidget(SCI(view)), pane->addWidget(SCI(view2)), update_ui(); // ensure views are painted
	pane->setSizes(QList<int>{middle, middle});
}

// Removes all Scintilla views from the given pane and deletes them along with the child panes
// themselves.
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
	bool view_has_focus = view == focused_view;
	SciObject *orig_focused_view = focused_view;
	QWidget *other = pane->widget(!pane->indexOf(SCI(view)));
	auto other_pane = qobject_cast<QSplitter *>(other);
	other_pane ? remove_views(other_pane, delete_view) : delete_view(other);
	if (auto parent_pane = qobject_cast<QSplitter *>(pane->parentWidget()); parent_pane)
		parent_pane->replaceWidget(parent_pane->indexOf(pane), SCI(view));
	else // note: cannot use ternary operator here due to distinct pointer types.
		pane->parentWidget()->layout()->replaceWidget(pane, SCI(view));
	// Note: the previous operation likely triggered view_focused(), changing focused_view.
	// However, if it did not, focused_view may no longer exist, so switch to view if necessary.
	if (!view_has_focus && focused_view == orig_focused_view) focus_view(SCI(view));
	return (SCI(view_has_focus ? orig_focused_view : focused_view)->setFocus(), true);
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
	QSignalBlocker blocker{ta->ui->tabbar}; // prevent currentChanged
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
static void add_to_history(QComboBox *combo, const char *text) {
	if (int n = combo->count(); combo->itemText(n - 1) != text)
		combo->addItem(text), combo->setCurrentIndex(n);
}
void add_to_find_history(const char *text) { add_to_history(ta->ui->findCombo, text); }
void add_to_repl_history(const char *text) { add_to_history(ta->ui->replaceCombo, text); }
void set_entry_font(const char *name_) {
	const char *p = strrchr(name_, ' ');
	if (!p) return;
	std::string name{name_, static_cast<size_t>(p - name_)};
	int size = atoi(p);
	QFont font{name.c_str(), size ? size : -1};
	ta->ui->findCombo->setFont(font), ta->ui->replaceCombo->setFont(font);
}
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
		SCI(focused_view)->setFocus(), ta->ui->findBox->hide();
}
bool is_find_active() { return ta->ui->findBox->isVisible(); }

void focus_command_entry() {
	if (!SCI(command_entry)->isVisible())
		SCI(command_entry)->show(), SCI(command_entry)->setFocus();
	else
		SCI(focused_view)->setFocus(), SCI(command_entry)->hide();
}
bool is_command_entry_active() { return SCI(command_entry)->hasFocus(); }
int get_command_entry_height() { return SCI(command_entry)->height(); }
void set_command_entry_height(int height) {
	SCI(command_entry)->setMinimumHeight(height);
	qobject_cast<QSplitter *>(SCI(command_entry)->parent())->setSizes(QList<int>{ta->height()});
}

void set_statusbar_text(int bar, const char *text) {
	bar == 0 ? ta->statusBar()->showMessage(text) : ta->docStatusBar->setText(text);
}

void *read_menu(lua_State *L, int index) {
	auto menu = new QMenu; // TODO: this is never deleted (it is never reparented)
	if (lua_getfield(L, index, "title")) menu->setTitle(lua_tostring(L, -1)); // submenu title
	lua_pop(L, 1); // title
	for (size_t i = 1; i <= lua_rawlen(L, index); lua_pop(L, 1), i++) {
		if (lua_rawgeti(L, -1, i) != LUA_TTABLE) continue; // popped on loop
		if (bool isSubmenu = lua_getfield(L, -1, "title"); lua_pop(L, 1), isSubmenu) {
			auto submenu = static_cast<QMenu *>(read_menu(L, -1));
			menu->addMenu(submenu); // menu does not take ownership
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
			menuItem->setShortcutContext(Qt::ShortcutContext::WidgetShortcut);
		}
		int id = get_int_field(L, -1, 2);
		QObject::connect(
			menuItem, &QAction::triggered, menu, [id]() { emit("menu_clicked", LUA_TNUMBER, id, -1); });
	}
	return menu;
}

void popup_menu(void *menu, void *userdata) {
	static_cast<QMenu *>(menu)->popup(
		userdata ? static_cast<QMouseEvent *>(userdata)->globalPos() : QCursor::pos());
}

void set_menubar(lua_State *L, int index) {
	ta->menuBar()->clear(); // does not delete menus
	for (size_t i = 1; i <= lua_rawlen(L, index); lua_pop(L, 1), i++) {
		auto menu = static_cast<QMenu *>(lua_rawgeti(L, index, i), lua_touserdata(L, -1));
		ta->menuBar()->addMenu(menu); // menubar does not take ownership
	}
	ta->menuBar()->setVisible(lua_rawlen(L, index) > 0);
}

char *get_clipboard_text(int *len) {
	const QString &text = QGuiApplication::clipboard()->text();
	*len = text.size();
	return static_cast<char *>(memcpy(malloc(*len), text.toStdString().c_str(), *len));
}

// An active timeout that cleans up after itself.
class Timeout {
public:
	Timeout(double interval, bool (*f)(int *), int *refs) : timer{new QTimer{ta}} {
		QObject::connect(timer, &QTimer::timeout, timer, [this, f, refs]() {
			if (!f(refs)) delete this;
		});
		timer->setInterval(interval * 1000), timer->start();
	}
	~Timeout() { delete timer; }

private:
	QTimer *timer;
};

void add_timeout(double interval, bool (*f)(int *), int *refs) { new Timeout{interval, f, refs}; }

void update_ui() { QApplication::sendPostedEvents(), QApplication::processEvents(); }

bool is_dark_mode() {
	QPalette palette;
	return palette.color(QPalette::WindowText).lightness() >
		palette.color(QPalette::Window).lightness();
}

int message_dialog(DialogOptions opts, lua_State *L) {
	QMessageBox dialog{ta};
	if (opts.title) dialog.setText(opts.title);
	if (opts.text) dialog.setInformativeText(opts.text);
	if (opts.icon && strcmp(opts.icon, "dialog-question") == 0)
		dialog.setIcon(QMessageBox::Question);
	else if (opts.icon && strcmp(opts.icon, "dialog-information") == 0)
		dialog.setIcon(QMessageBox::Information);
	else if (opts.icon && strcmp(opts.icon, "dialog-warning") == 0)
		dialog.setIcon(QMessageBox::Warning);
	else if (opts.icon && strcmp(opts.icon, "dialog-error") == 0)
		dialog.setIcon(QMessageBox::Critical);
	else if (opts.icon && QIcon::hasThemeIcon(opts.icon))
		dialog.setIconPixmap(QIcon::fromTheme(opts.icon).pixmap(
			QApplication::style()->pixelMetric(QStyle::PM_MessageBoxIconSize)));
	if (opts.buttons[2]) dialog.addButton(opts.buttons[2], static_cast<QMessageBox::ButtonRole>(2));
	if (opts.buttons[1]) dialog.addButton(opts.buttons[1], static_cast<QMessageBox::ButtonRole>(1));
	dialog.setDefaultButton(
		dialog.addButton(opts.buttons[0], static_cast<QMessageBox::ButtonRole>(0)));
	for (auto &button : dialog.buttons()) button->setFocusPolicy(Qt::StrongFocus);
	dialog.exec(); // QMessageBox returns an opaque value
	ta->window()->activateWindow(); // macOS does not restore main window focus, so force it.
	return (lua_pushinteger(L, dialog.buttonRole(dialog.clickedButton()) + 1), 1);
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
	if (dialog.fileMode() == QFileDialog::Directory && opts->dir) opts->file = opts->dir; // for Linux
	if (opts->dir) dialog.setDirectory(opts->dir);
	if (opts->file) dialog.selectFile(opts->file);
	if (!dialog.exec()) return 0;
	lua_newtable(L); // note: will be replaced by a single value if opts->multiple is false
	for (int i = 0; i < dialog.selectedFiles().size(); i++)
		lua_pushstring(L, dialog.selectedFiles()[i].toLocal8Bit().data()), lua_rawseti(L, -2, i + 1);
	if (!opts->multiple) lua_rawgeti(L, -1, 1), lua_replace(L, -2); // single value
	return 1;
}

int open_dialog(DialogOptions opts, lua_State *L) { return open_save_dialog(&opts, L, true); }
int save_dialog(DialogOptions opts, lua_State *L) { return open_save_dialog(&opts, L, false); }

// Updates the given progressbar dialog with the given percentage and text.
static void update(double percent, const char *text, void *dialog_) {
	auto dialog = static_cast<QProgressDialog *>(dialog_);
	if (percent >= 0)
		dialog->setValue(percent);
	else if (dialog->maximum() > 0)
		dialog->setMaximum(0), dialog->show(); // switch to indeterminate and show immediately
	if (text) dialog->setLabelText(text);
}

int progress_dialog(
	DialogOptions opts, lua_State *L, bool (*work)(void (*)(double, const char *, void *), void *)) {
	QProgressDialog dialog{opts.title ? opts.title : "", opts.buttons[0], 0, 100};
	dialog.setWindowModality(Qt::WindowModal), dialog.setMinimumDuration(0);
	while (work(update, &dialog))
		if (QApplication::processEvents(), dialog.wasCanceled()) break;
	return dialog.wasCanceled() ? (lua_pushboolean(L, true), 1) : 0;
}

// Event filter that forwards keypresses to a target widget.
// This is primarily used to forward movement keys from the list dialog's line edit to its
// tree view. This allows for cursor movement from the line edit while it has focus.
class KeyForwarder : public QObject {
public:
	KeyForwarder(QWidget *target, QObject *parent = nullptr) : QObject{parent}, target{target} {}

protected:
	bool eventFilter(QObject *watched, QEvent *event) override {
		if (event->type() != QEvent::KeyPress) return false;
		int key = static_cast<QKeyEvent *>(event)->key();
		if (key != Qt::Key_Down && key != Qt::Key_Up && key != Qt::Key_PageDown &&
			key != Qt::Key_PageUp)
			return false;
		return (target->setFocus(), QApplication::sendEvent(target, event),
			qobject_cast<QWidget *>(watched)->setFocus(), true);
	}
	QWidget *target;
};

int list_dialog(DialogOptions opts, lua_State *L) {
	int numColumns = opts.columns ? lua_rawlen(L, opts.columns) : 1,
			numItems = lua_rawlen(L, opts.items);
	QStandardItemModel model{numItems / numColumns, numColumns};
	for (int i = 1; i <= numColumns; i++) {
		const char *header = opts.columns ? (lua_rawgeti(L, opts.columns, i), lua_tostring(L, -1)) : "";
		model.setHorizontalHeaderItem(i - 1, new QStandardItem{QString{header}});
		if (opts.columns) lua_pop(L, 1); // header
	}
	for (int i = 0; i < numItems; lua_pop(L, 1), i++) {
		const char *item = (lua_rawgeti(L, opts.items, i + 1), lua_tostring(L, -1));
		auto qitem = new QStandardItem{QString{item}};
		model.setItem(i / numColumns, i % numColumns, (qitem->setEditable(false), qitem));
	}
	QSortFilterProxyModel filter;
	filter.setFilterKeyColumn(opts.search_column - 1);
	filter.setSourceModel(&model);

	QDialog dialog{ta};
	auto vbox = new QVBoxLayout{&dialog};
	if (opts.title) vbox->addWidget(new QLabel{opts.title});
	auto lineEdit = new QLineEdit;
	QObject::connect(lineEdit, &QLineEdit::returnPressed, &dialog, &QDialog::accept);
	auto treeView = new QTreeView;
	treeView->setModel(&filter);
	treeView->setHeaderHidden(!opts.columns), treeView->setIndentation(0);
	treeView->header()->resizeSections(QHeaderView::ResizeToContents);
	treeView->setSelectionBehavior(QAbstractItemView::SelectRows);
	QObject::connect(treeView, &QTreeView::doubleClicked, &dialog, &QDialog::accept);
	if (opts.multiple) treeView->setSelectionMode(QAbstractItemView::ExtendedSelection);
	QItemSelectionModel *selection = treeView->selectionModel();
	QObject::connect(
		lineEdit, &QLineEdit::textChanged, &filter, [&filter, &selection](const QString &text) {
			// TODO: Qt 5.15 introduced QRegularExpression::escape().
			// QString re = QRegularExpression::escape(text).replace("\\ ", ".*");
			QString re =
				QString{text}.replace(QRegularExpression{"([^A-Za-z0-9_])"}, "\\\\1").replace("\\ ", ".*");
			filter.setFilterRegularExpression(
				QRegularExpression{re, QRegularExpression::CaseInsensitiveOption});
			selection->select(
				filter.index(0, 0), QItemSelectionModel::Select | QItemSelectionModel::Rows);
		});
	if (opts.text) lineEdit->setText(opts.text);
	selection->select(filter.index(0, 0), QItemSelectionModel::Select | QItemSelectionModel::Rows);
	lineEdit->installEventFilter(new KeyForwarder{treeView, &dialog});
	auto buttonBox = new QDialogButtonBox;
	int buttonClicked = 1; // ok/accept by default
	if (opts.buttons[2])
		buttonBox->addButton(opts.buttons[2], static_cast<QDialogButtonBox::ButtonRole>(2));
	if (opts.buttons[1])
		buttonBox->addButton(opts.buttons[1], static_cast<QDialogButtonBox::ButtonRole>(1));
	buttonBox->addButton(opts.buttons[0], static_cast<QDialogButtonBox::ButtonRole>(0));
	QObject::connect(buttonBox, &QDialogButtonBox::clicked, buttonBox,
		[buttonBox, &buttonClicked](QAbstractButton *button) {
			buttonClicked = buttonBox->buttonRole(button) + 1;
			if (buttonClicked == 3) Q_EMIT(buttonBox->accepted());
		});
	QObject::connect(buttonBox, &QDialogButtonBox::accepted, &dialog, &QDialog::accept);
	QObject::connect(buttonBox, &QDialogButtonBox::rejected, &dialog, &QDialog::reject);
	vbox->addWidget(lineEdit), vbox->addWidget(treeView), vbox->addWidget(buttonBox);
	int treeViewWidth = 0;
	for (int i = 0; i < numColumns; i++) treeViewWidth += treeView->columnWidth(i);
	dialog.resize(treeViewWidth, treeViewWidth * 10 / 16); // 16:10 ratio

	bool ok = dialog.exec();
	if (!ok && !opts.return_button) return 0;
	lua_newtable(L); // note: will be replaced by a single result if opts.multiple is false
	for (int i = 0; i < selection->selectedRows(0).size(); i++)
		lua_pushinteger(L, filter.mapToSource(selection->selectedRows(0)[i]).row() + 1),
			lua_rawseti(L, -2, i + 1);
	if (!opts.multiple) lua_rawgeti(L, -1, 1), lua_replace(L, -2); // single value
	return !opts.return_button ? 1 : (lua_pushinteger(L, ok ? buttonClicked : 2), 2);
}

// Contains information about an active process.
// Note: C++ does not allow `struct Process`, unlike C.
struct _process {
	QProcess *proc = nullptr;
};
static inline QProcess *PROCESS(Process *p) { return static_cast<struct _process *>(p)->proc; }

bool spawn(lua_State *L, Process *proc, int /*index*/, const char *cmd, const char *cwd, int envi,
	bool monitor_stdout, bool monitor_stderr, const char **error) {
#if _WIN32
	// Use "cmd.exe /c" for more versatility (e.g. spawning batch files).
	std::string full_cmd = std::string{getenv("COMSPEC")} + " /c " + cmd;
	cmd = full_cmd.c_str();
#endif
	// Construct argv from cmd and envp from envi.
	// TODO: Qt 5.15 introduced QProcess::splitCommand().
	// QStringList args = QProcess::splitCommand(QString{cmd}).
	QStringList args;
	const char *p = cmd;
	while (*p) {
		while (*p == ' ') p++;
		std::string arg;
		do {
			const char *s = p;
			while (*p && *p != ' ' && *p != '"' && *p != '\'') p++;
			arg.append(s, p - s);
			if (*p == '"' || *p == '\'') {
				s = p + 1;
				for (char q = *p++; *p && (*p != q || *(p - 1) == '\\'); p++) {}
				arg.append(s, p - s);
				if (*p == '"' || *p == '\'') p++;
			}
		} while (*p && *p != ' ');
		args.append(arg.c_str());
	}
	QProcessEnvironment env;
	if (envi)
		for (int i = (lua_pushnil(L), 0); lua_next(L, envi); lua_pop(L, 1), i++) {
			std::string pair{lua_tostring(L, -1)};
			env.insert(pair.substr(0, pair.find('=')).c_str(), pair.substr(pair.find('=') + 1).c_str());
		}

	auto qProc = new QProcess;
	qProc->setProgram(args.takeFirst()), qProc->setArguments(args);
	if (cwd) qProc->setWorkingDirectory(cwd);
	qProc->setProcessEnvironment(envi ? env : QProcessEnvironment::systemEnvironment());
	if (monitor_stdout)
		QObject::connect(qProc, &QProcess::readyReadStandardOutput, qProc, [proc, qProc]() {
			QByteArray bytes = qProc->readAllStandardOutput();
			process_output(proc, bytes.data(), bytes.size(), true);
		});
	if (monitor_stderr)
		QObject::connect(qProc, &QProcess::readyReadStandardError, qProc, [proc, qProc]() {
			QByteArray bytes = qProc->readAllStandardError();
			process_output(proc, bytes.data(), bytes.size(), false);
		});
	QObject::connect(qProc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), qProc,
		[proc](int exitCode, QProcess::ExitStatus) { process_exited(proc, exitCode); });
	qProc->start();
	if (!qProc->waitForStarted(500)) return (*error = "process failed to start", false);
	return (static_cast<struct _process *>(proc)->proc = qProc, true);
}

size_t process_size() { return sizeof(struct _process); }

bool is_process_running(Process *proc) { return PROCESS(proc)->state() == QProcess::Running; }

void wait_process(Process *proc) { PROCESS(proc)->waitForFinished(-1); }

char *read_process_output(Process *proc, char option, size_t *len, const char **error, int *code) {
	QSignalBlocker blocker{PROCESS(proc)}; // prevent readyReadStandardOutput
	if (option == 'n') {
		while (static_cast<size_t>(PROCESS(proc)->bytesAvailable()) < *len)
			PROCESS(proc)->waitForReadyRead(-1);
		auto buf = static_cast<char *>(malloc(*len));
		*len = PROCESS(proc)->read(buf, *len);
		return *len == 0 ? (*error = nullptr, nullptr) : buf;
	}
	int n;
	char ch;
	std::string output;
	if (!PROCESS(proc)->bytesAvailable()) PROCESS(proc)->waitForReadyRead(-1);
	while ((n = PROCESS(proc)->read(&ch, 1)) > 0) {
		if ((ch != '\r' && ch != '\n') || option == 'L' || option == 'a') output.push_back(ch);
		if (ch == '\n' && option != 'a') break;
		if (!PROCESS(proc)->bytesAvailable()) PROCESS(proc)->waitForReadyRead(-1);
	}
	*len = output.size();
	if (n < 0 && !*len && option != 'a') {
		static std::string err;
		err = PROCESS(proc)->errorString().toStdString();
		return (*error = err.c_str(), *code = QProcess::ReadError, nullptr);
	}
	if (n == 0 && !*len && option != 'a') return (*error = nullptr, nullptr); // EOF
	return (*error = nullptr, strcpy(static_cast<char *>(malloc(*len + 1)), output.c_str()));
}

void write_process_input(Process *proc, const char *s, size_t len) { PROCESS(proc)->write(s, len); }

void close_process_input(Process *proc) { PROCESS(proc)->closeWriteChannel(); }

void kill_process(Process *proc, int /*signal*/) { PROCESS(proc)->kill(); }

int get_process_exit_status(Process *proc) { return PROCESS(proc)->exitCode(); }

void cleanup_process(Process *proc) {
	// Prevent finished signal if the process is still running (likely quitting Textadept).
	QObject::disconnect(PROCESS(proc), nullptr, nullptr, nullptr);
	delete PROCESS(proc);
}

void suspend() {}

void quit() { ta->close(); }

// Event filter for find & replace comboboxes that activates a find/replace button when Enter
// is pressed, and another button when Shift+Enter is pressed.
class FindKeypressHandler : public QObject {
public:
	FindKeypressHandler(QObject *parent = nullptr) : QObject{parent} {}

protected:
	bool eventFilter(QObject *watched, QEvent *event) override {
		if (event->type() != QEvent::KeyPress) return false;
		auto keyEvent = static_cast<QKeyEvent *>(event);
		if (keyEvent->key() != Qt::Key_Return && keyEvent->key() != Qt::Key_Enter) return false;
		auto button = (keyEvent->modifiers() & Qt::ShiftModifier) == 0 ?
			(watched == ta->ui->findCombo ? ta->ui->findNext : ta->ui->replace) :
			(watched == ta->ui->findCombo ? ta->ui->findPrevious : ta->ui->replaceAll);
		return (find_clicked(button), true);
	}
};

Textadept::Textadept(QWidget *parent) : QMainWindow{parent}, ui{new Ui::Textadept} {
	ui->setupUi(this);

	connect(ui->tabbar, &QTabBar::tabBarClicked, this, [this](int index) {
		Qt::MouseButtons button = QApplication::mouseButtons();
		// Qt emits tabBarClicked before updating the current tab for left button clicks.
		// If the "tab_clicked" event were to be emitted here, it could update the current tab, and
		// then Qt could do so again, but with the wrong tab index. Instead, only emit "tab_clicked"
		// here under certain conditions, relying on currentChanged to do so otherwise.
		if (button == Qt::LeftButton && index != ui->tabbar->currentIndex()) return;
		emit("tab_clicked", LUA_TNUMBER, index + 1, LUA_TNUMBER, button, LUA_TNUMBER,
			scModMask(QApplication::keyboardModifiers()), -1);
		if (button == Qt::RightButton) show_context_menu("tab_context_menu", nullptr);
	});
	connect(ui->tabbar, &QTabBar::currentChanged, this, [](int index) {
		emit("tab_clicked", LUA_TNUMBER, index + 1, LUA_TNUMBER, Qt::LeftButton, LUA_TNUMBER,
			scModMask(QApplication::keyboardModifiers()), -1);
	});
	connect(ui->tabbar, &QTabBar::tabMoved, this,
		[](int from, int to) { move_buffer(from + 1, to + 1, false); });
	connect(ui->tabbar, &QTabBar::tabCloseRequested, this,
		[](int index) { emit("tab_close_clicked", LUA_TNUMBER, index + 1, -1); });

	ui->findCombo->setCompleter(nullptr), ui->replaceCombo->setCompleter(nullptr);
	auto filter = new FindKeypressHandler{this};
	ui->findCombo->installEventFilter(filter), ui->replaceCombo->installEventFilter(filter);
	connect(ui->findCombo->lineEdit(), &QLineEdit::textChanged, this,
		[]() { emit("find_text_changed", -1); });
	find_next = ui->findNext, find_prev = ui->findPrevious, replace = ui->replace,
	replace_all = ui->replaceAll;
	match_case = ui->matchCase, whole_word = ui->wholeWord, regex = ui->regex, in_files = ui->inFiles;
	auto clicked = [this]() { find_clicked(QObject::sender()); };
	connect(ui->findNext, &QPushButton::clicked, this, clicked);
	connect(ui->findPrevious, &QPushButton::clicked, this, clicked);
	connect(ui->replace, &QPushButton::clicked, this, clicked);
	connect(ui->replaceAll, &QPushButton::clicked, this, clicked);

	statusBar()->addPermanentWidget(docStatusBar = new QLabel);
	ui->tabFrame->hide(), SCI(command_entry)->hide(), ui->findBox->hide();
}

void Textadept::closeEvent(QCloseEvent *ev) {
	if (!can_quit()) ev->ignore();
}

void Textadept::keyPressEvent(QKeyEvent *ev) {
	if (ev->key() == Qt::Key_Escape && ui->findBox->isVisible() && !SCI(command_entry)->hasFocus())
		SCI(focused_view)->setFocus(), ui->findBox->hide(), ev->ignore();
}

// The Textadept application.
class Application : public SingleApplication {
public:
	Application(int &argc, char **argv) : SingleApplication{argc, argv, true} {
		const std::vector<const char *> args{"-f", "--force", "-L", "--lua"};
		bool force =
			std::any_of(args.begin(), args.end(), [](const char *s) { return arguments().contains(s); });
		if (isSecondary() && !force) {
			QByteArray bytes;
			QDataStream out{&bytes, QIODevice::WriteOnly};
			out << QDir::currentPath() << arguments();
			sendMessage(bytes);
			return;
		}
		if (inited = init_textadept(argc, argv); !inited) return;
		setApplicationName("Textadept");
#if !__APPLE__
		setWindowIcon(QIcon{QString{textadept_home} + "/core/images/textadept.svg"});
#else
		setWindowIcon(QIcon{QString{textadept_home} + "/core/images/textadept_mac.png"});
		// Read $PATH from shell since macOS GUI apps run in a limited environment.
		QProcess p;
		p.startCommand(qgetenv("SHELL") + " -l -c env"), p.waitForFinished();
		QRegularExpression re{"^([^=]+)=(.+)$", QRegularExpression::MultilineOption};
		for (const auto &match : re.globalMatch(p.readAll()))
			qputenv(match.captured(1).toLocal8Bit(), match.captured(2).toLocal8Bit());
#endif
		connect(this, &SingleApplication::receivedMessage, this, [](quint32, QByteArray message) {
			ta->window()->activateWindow();
			QDataStream in{&message, QIODevice::ReadOnly};
			QString cwd;
			QStringList args;
			in >> cwd >> args;
			if (args.size() == 0) return;
			lua_newtable(lua);
			lua_pushstring(lua, cwd.toLocal8Bit().data()), lua_rawseti(lua, -2, -1);
			for (int i = 0; i < args.size(); i++)
				lua_pushstring(lua, args[i].toLocal8Bit().data()), lua_rawseti(lua, -2, i);
			emit("command_line", LUA_TTABLE, luaL_ref(lua, LUA_REGISTRYINDEX), -1);
		});
		connect(this, &QGuiApplication::applicationStateChanged, this, [](Qt::ApplicationState state) {
			if (state == Qt::ApplicationInactive)
				emit("unfocus", -1);
			else if (state == Qt::ApplicationActive)
				emit("focus", -1);
		});
		connect(this, &QGuiApplication::paletteChanged, this, mode_changed);
		connect(this, &QGuiApplication::commitDataRequest, this, [](QSessionManager &manager) {
			if (manager.allowsInteraction() && emit("quit", -1)) manager.cancel();
		});
		connect(this, &QApplication::aboutToQuit, this, &close_textadept);
		// There is a bug in Qt where a tab scroll button could have focus at this time.
		if (!SCI(focused_view)->hasFocus()) SCI(focused_view)->setFocus();
	}
	~Application() override {
		if (inited) delete ta;
	}

	int exec() { return inited ? (QApplication::exec(), exit_status) : exit_status; }

protected:
	bool event(QEvent *event) override {
		if (event->type() == QEvent::FileOpen)
			emit("appleevent_odoc", LUA_TSTRING,
				static_cast<QFileOpenEvent *>(event)->file().toStdString().c_str(), -1);
		return QApplication::event(event);
	}

private:
	bool inited = false;
};

int main(int argc, char *argv[]) { return Application{argc, argv}.exec(); }
