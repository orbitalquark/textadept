// Copyright 2026 Mitchell. See LICENSE.
// Shim for designating the application's "Window" menu in the menubar.
// This can go away once Qt supports it (https://qt-project.atlassian.net/browse/QTBUG-131669).

#include "textadept_qt_mac.h"

#include <AppKit/AppKit.h>

void setWindowsMenu(void *menu_) {
	[NSApp setWindowsMenu:(__bridge NSMenu*)menu_];
	// For some reason, every time a dialog is opened and closed, macOS adds a new "Enter Full
	// Screen" menu item to the "Window" menu, even though one exists in "View".
	// I tried fiddling with modality, parent widgets, window flags, etc. Nothing worked. Just
	// disable this until Qt properly supports the "Window" menu.
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NSFullScreenMenuItemEverywhere"];
}
