// Copyright 2007 Mitchell mitchell<att>caladbolg.net. See LICENSE.

#ifndef PROPERTIES_H
#define PROPERTIES_H

#include "textadept.h"

#define sp(k, v) SSS(sci, SCI_SETPROPERTY, k, v)
#define color(r, g, b) r | (g << 8) | (b << 16)

void set_default_editor_properties(ScintillaObject *sci) {
  sp("lexer.lua.home", "/usr/share/textadept/lexers/");
  sp("lexer.lua.script", "/usr/share/textadept/lexers/lexer.lua");

  // caret
  SS(sci, SCI_SETCARETFORE, color(0xAA, 0xAA, 0xAA));
  SS(sci, SCI_SETCARETLINEVISIBLE, true);
  SS(sci, SCI_SETCARETLINEBACK, color(0x44, 0x44, 0x44));
  SS(sci, SCI_SETXCARETPOLICY, CARET_SLOP, 20);
  SS(sci, SCI_SETYCARETPOLICY, CARET_SLOP | CARET_STRICT | CARET_EVEN, 1);
  SS(sci, SCI_SETCARETSTYLE, 2);
  SS(sci, SCI_SETCARETPERIOD, 0);

  // selection
  SS(sci, SCI_SETSELFORE, 1, color(0x33, 0x33, 0x33));
  SS(sci, SCI_SETSELBACK, 1, color(0x99, 0x99, 0x99));

  SS(sci, SCI_SETBUFFEREDDRAW, 1);
  SS(sci, SCI_SETTWOPHASEDRAW, 0);
  SS(sci, SCI_CALLTIPUSESTYLE, 32);
  SS(sci, SCI_USEPOPUP, 0);
  SS(sci, SCI_SETFOLDFLAGS, 16);
  SS(sci, SCI_SETMODEVENTMASK, SC_MOD_CHANGEFOLD);

  SS(sci, SCI_SETMARGINWIDTHN, 0, 4 + 2 * // line number margin
     SS(sci, SCI_TEXTWIDTH, STYLE_LINENUMBER, reinterpret_cast<long>("9")));

  SS(sci, SCI_SETMARGINWIDTHN, 1, 0); // marker margin invisible

  // fold margin
  SS(sci, SCI_SETFOLDMARGINCOLOUR, 1, color(0xAA, 0xAA, 0xAA));
  SS(sci, SCI_SETFOLDMARGINHICOLOUR, 1, color(0xAA, 0xAA, 0xAA));
  SS(sci, SCI_SETMARGINTYPEN, 2, SC_MARGIN_SYMBOL);
  SS(sci, SCI_SETMARGINWIDTHN, 2, 10);
  SS(sci, SCI_SETMARGINMASKN, 2, SC_MASK_FOLDERS);
  SS(sci, SCI_SETMARGINSENSITIVEN, 2, 1);

  // fold margin markers
  SS(sci, SCI_MARKERDEFINE, SC_MARKNUM_FOLDEROPEN, SC_MARK_ARROWDOWN);
	SS(sci, SCI_MARKERSETFORE, SC_MARKNUM_FOLDEROPEN, 0);
	SS(sci, SCI_MARKERSETBACK, SC_MARKNUM_FOLDEROPEN, 0);
  SS(sci, SCI_MARKERDEFINE, SC_MARKNUM_FOLDER, SC_MARK_ARROW);
	SS(sci, SCI_MARKERSETFORE, SC_MARKNUM_FOLDER, 0);
	SS(sci, SCI_MARKERSETBACK, SC_MARKNUM_FOLDER, 0);
  SS(sci, SCI_MARKERDEFINE, SC_MARKNUM_FOLDERSUB, SC_MARK_EMPTY);
  SS(sci, SCI_MARKERDEFINE, SC_MARKNUM_FOLDERTAIL, SC_MARK_EMPTY);
  SS(sci, SCI_MARKERDEFINE, SC_MARKNUM_FOLDEREND, SC_MARK_EMPTY);
  SS(sci, SCI_MARKERDEFINE, SC_MARKNUM_FOLDEROPENMID, SC_MARK_EMPTY);
  SS(sci, SCI_MARKERDEFINE, SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_EMPTY);

  SS(sci, SCI_SETSCROLLWIDTH, 2000);
  SS(sci, SCI_SETHSCROLLBAR, 1);
  SS(sci, SCI_SETENDATLASTLINE, 1);
  SS(sci, SCI_SETCARETSTICKY, 0);
}

void set_default_buffer_properties(ScintillaObject *sci) {
  sp("fold", "1");
  sp("fold.by.indentation", "1");

  SS(sci, SCI_SETLEXER, SCLEX_LPEG);
  SS(sci, SCI_SETLEXERLANGUAGE, 0, reinterpret_cast<long>("container"));

  // Tabs and indentation
  SS(sci, SCI_SETTABWIDTH, 2);
  SS(sci, SCI_SETUSETABS, 0);
  SS(sci, SCI_SETINDENT, 2);
  SS(sci, SCI_SETTABINDENTS, 1);
  SS(sci, SCI_SETBACKSPACEUNINDENTS, 1);
  SS(sci, SCI_SETINDENTATIONGUIDES, 1);

  SS(sci, SCI_SETEOLMODE, SC_EOL_LF);
  SS(sci, SCI_AUTOCSETCHOOSESINGLE, 1);
}

#endif
