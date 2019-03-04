How do build an NSIS installer:

Copy the statically linked binaries into this directory.
The name should be `qpdfview-x64.exe` for 64 bit and `qpdfview-x86.exe` for 32 bit.
Make sure to update the information in `THIRDPARTY.txt`.

Open MakeNSIS and drag `installer.nsi` into the window.
The 32 bit installer should now build. After that's done, open the settings (Ctrl + S)
and add the symbol `ARCH_X64` to the symbol list. Confirm with OK and recompile (Ctrl + R).
The 64 bit installer should now compile.
