// Copyright 2022 Mitchell. See LICENSE.
// Qt platform for Textadept.

#include "textadept_qt_ui.h"

namespace Ui {
class Textadept;
}

class Textadept : public QMainWindow {
  Q_OBJECT

public:
  explicit Textadept(QWidget *parent = nullptr);
  ~Textadept() override = default;

  Ui::Textadept *ui;
  QLabel *docStatusBar;

protected:
  void closeEvent(QCloseEvent *ev) override;
  void focusInEvent(QFocusEvent *ev) override;
  void focusOutEvent(QFocusEvent *ev) override;
  void keyPressEvent(QKeyEvent *ev) override;
};
