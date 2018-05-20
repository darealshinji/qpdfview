#!/bin/bash
set -e

# helper script for mingw32 builds via MXE (https://github.com/mxe/mxe)

mxe_base="$HOME/dev/mxe"

mxe_target="i686-w64-mingw32.static"
#mxe_target="i686-w64-mingw32.shared"
#mxe_target="x86_64-w64-mingw32.static"
#mxe_target="x86_64-w64-mingw32.shared"

pkgconfig="${mxe_target}-pkg-config"
strip="${mxe_target}-strip"
cxx="${mxe_target}-g++"
qmake="${mxe_target}-qmake-qt5"

export PATH="$mxe_base/usr/$mxe_target/qt5/bin:$mxe_base/usr/bin:$PATH"

### clean up
test -f Makefile && (make distclean || true)
rm -f Makefile* qpdfview_win32.pri miscellaneous/qpdfview.desktop
rm -f translations/*.qm
rm -rf moc moc-* objects objects-*
#exit

### win32 settings
cat <<EOF > qpdfview_win32.pri
APPLICATION_VERSION = 0.4.17

CONFIG -= debug
CONFIG -= debug_and_release
CONFIG -= debug_and_release_target

CONFIG += without_pkgconfig
CONFIG += without_magic
CONFIG += without_cups
CONFIG += without_synctex
CONFIG += without_signals
CONFIG += static_resources

$($pkgconfig --atleast-version=0.14 poppler-qt5 && echo 'DEFINES += HAS_POPPLER_14')
$($pkgconfig --atleast-version=0.18 poppler-qt5 && echo 'DEFINES += HAS_POPPLER_18')
$($pkgconfig --atleast-version=0.20.1 poppler-qt5 && echo 'DEFINES += HAS_POPPLER_20')
$($pkgconfig --atleast-version=0.22 poppler-qt5 && echo 'DEFINES += HAS_POPPLER_22')
$($pkgconfig --atleast-version=0.24 poppler-qt5 && echo 'DEFINES += HAS_POPPLER_24')
$($pkgconfig --atleast-version=0.26 poppler-qt5 && echo 'DEFINES += HAS_POPPLER_26')
$($pkgconfig --atleast-version=0.31 poppler-qt5 && echo 'DEFINES += HAS_POPPLER_31')
$($pkgconfig --atleast-version=0.35 poppler-qt5 && echo 'DEFINES += HAS_POPPLER_35')

POPPLER_VERSION    = $($pkgconfig --modversion poppler-qt5)
LIBSPECTRE_VERSION = $($pkgconfig --modversion libspectre)
DJVULIBRE_VERSION  = $($pkgconfig --modversion ddjvuapi)

PDF_PLUGIN_INCLUDEPATH  += $($pkgconfig --cflags-only-I poppler-qt5 | sed 's|-I\/|\/|g')
PDF_PLUGIN_LIBS         += $($pkgconfig --libs poppler-qt5 lcms2)

PS_PLUGIN_INCLUDEPATH   += $($pkgconfig --cflags-only-I libspectre | sed 's|-I\/|\/|g')
PS_PLUGIN_LIBS          += $($pkgconfig --libs libspectre)

DJVU_PLUGIN_INCLUDEPATH += $($pkgconfig --cflags-only-I ddjvuapi | sed 's|-I\/|\/|g')
DJVU_PLUGIN_LIBS        += $($pkgconfig --libs ddjvuapi)
EOF

### link plugins statically
case $mxe_target in
  *.static)
  cat <<EOF >> qpdfview_win32.pri
CONFIG += static_pdf_plugin
CONFIG += static_ps_plugin
CONFIG += static_djvu_plugin
CONFIG += static_image_plugin
DEFINES += DJVU_STATIC
EOF
  ;;
esac

### compile translations
lrelease qpdfview.pro

### build qpdfview
$qmake qpdfview.pro
make qmake_all
sed -i 's|-lqpdfview_|libqpdfview_|g' Makefile.application  # bug
make -j4

