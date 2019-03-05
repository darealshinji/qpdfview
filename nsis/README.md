How do build an NSIS installer:

Copy the statically linked binaries into this directory.
The name should be `qpdfview-x64.exe` for 64 bit and `qpdfview-x86.exe` for 32 bit.
Make sure to update the information in `THIRDPARTY.txt`.

On Windows:

Open MakeNSIS and drag `installer.nsi` into the window.
The 32 bit installer should now build. After that's done, open the settings (Ctrl + S)
and add the symbol `ARCH_X64` to the symbol list. Confirm with OK and recompile (Ctrl + R).
The 64 bit installer should now compile.

On Linux:

Install the command line version of NSIS (`apt install nsis` on Debian & co).
Run the following commands to build the installers (`-V4` is only for verbosity):
```
makensis -V4 installer.nsi
makensis -V4 -DARCH_X64 installer.nsi
```

Build latest NSIS from source on Linux, the quick way:

Download the latest source tarball (nsis-x.xx-src.tar.bz2) and zipped release version (nsis-x.xx.zip)
from [SourceForge](https://sourceforge.net/projects/nsis/files/) and extract both archives.

Run the following command inside the source directory:
```
scons -j4 SKIPSTUBS=all SKIPPLUGINS=all SKIPUTILS=all SKIPMISC=all NSIS_CONFIG_CONST_DATA_PATH=no APPEND_LINKFLAGS="-static -s" makensis
```

After the build is finished, copy the binary file `nsis-x.xx-src/build/urelease/makensis/makensis` into `nsis-x.xx/Bin/`.
You can now run makensis from that directory to build the installer: `/PATH/TO/nsis-x.xx/Bin/makensis /PATH/TO/installer.nsi`

