## FAQ

**Q:**
Why does Textadept fail to run on Linux? Why does the terminal version behave oddly or crash?

**A:**
It is not possible to provide a single Textadept binary that runs correctly on all Linux
systems. You must [compile][] Textadept manually for your system.

[compile]: manual.html#compiling

- - -

**Q:**
Why does my Windows anti-virus software say Textadept contains a virus?

**A:**
This is a false-positive, caused by Textadept's terminal version executable, which is a console
application. Textadept does not contain any viruses.

- - -

**Q:**
Why does Textadept fail to correctly display my non-English file?

**A:**
Textadept failed to detect the file's encoding. You'll need to [help it][].

On Windows, if you are seeing strange characters in the filename (including '?'), your file's name
contains characters outside the system's encoding. You can try the following as an administrator:
1. Open Settings
2. Select "Time & language"
3. Select "Administrative language settings"
4. Click "Change system locale..."
5. Check the "Beta: Use Unicode UTF-8 for worldwide language support" box
6. Restart your computer
7. Try opening the file again

[help it]: manual.html#encoding

- - -

**Q:**

On my Windows HiDPI display at fractional scaling (e.g. 125% or 150%), Textadept does not render
text lines correctly. How do I fix it?

**A:**

Either use integer scaling (e.g. 200%), or instruct Windows to take over font rendering for
the application: right-click on the Textadept executable and select "Properties"; click on the
"Compatibility" tab and then the "Change high DPI settings" button; and check the "Override high
DPI scaling" checkbox towards the bottom of the pop-up dialog. The next time you run Textadept,
things should look better.

- - -

**Q:**
Why doesn't middle-clicking in the terminal version on Linux paste the primary selection? Why
doesn't selecting text copy to the primary selection?

**A:**
Textadept interprets mouse clicks like a GUI application. Use the `Shift` modifier key when
you middle-click or select text to interact with the primary selection.

- - -

**Q:**
Why doesn't the terminal version support feature _x_ that the GUI version does?

**A:**
The manual's appendix has a section on [terminal version compatibility][]. If the issue you are
seeing is listed there, then it's a known limitation.

[terminal version compatibility]: manual.html#terminal-version-compatibility

- - -

**Q:**
Why doesn't the terminal version show more than 8 colors?

**A:**
This largely depends on your operating system and terminal emulator settings. For example:

- macOS: Enable the "Use bright colors for bold text" setting in your Terminal.app preferences.
- Linux: Enable "Show bold text in bright colors" setting in your GNOME Terminal preferences.

- - -

**Q:**
Where can I find a complete list of key bindings for Textadept?

**A:**
[Here](api.html#textadept.keys).

