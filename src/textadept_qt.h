// Copyright 2022-2026 Mitchell. See LICENSE.
// Qt platform for Textadept.

#include "ui_textadept_qt.h"
#if __APPLE__
#include "textadept_qt_mac.h"
#endif

namespace Ui {
class Textadept;
}

// A Textadept window.
class Textadept : public QMainWindow {
	Q_OBJECT

public:
	explicit Textadept(QWidget *parent = nullptr);
	~Textadept() override = default;

	Ui::Textadept *ui;
	QLabel *docStatusBar; // permanent statusbar widget

protected:
	void closeEvent(QCloseEvent *ev) override;
	void keyPressEvent(QKeyEvent *ev) override;
};
