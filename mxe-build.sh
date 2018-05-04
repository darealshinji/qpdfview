#!/bin/bash
set -e

# helper script for static mingw32 builds via MXE (https://github.com/mxe/mxe)

mxe_base="$HOME/mxe"
mxe_target="i686-w64-mingw32.static"
pkgconfig="${mxe_target}-pkg-config"
strip="${mxe_target}-strip"
cxx="${mxe_target}-g++"
qmake="${mxe_target}-qmake-qt5"

export PATH="$mxe_base/usr/$mxe_target/qt/bin:$mxe_base/usr/bin:$PATH"


### win32 settings
cat <<EOF > qpdfview_win32.pri
isEmpty(APPLICATION_VERSION):APPLICATION_VERSION = 0.4.17

CONFIG += without_pkgconfig
CONFIG += without_magic
CONFIG += without_cups
CONFIG += without_synctex
CONFIG += without_signals
CONFIG += without_ps  # doesn't work correctly
CONFIG += with_staticresources
CONFIG += static_pdf_plugin
CONFIG += static_ps_plugin
CONFIG += static_djvu_plugin
CONFIG += static_image_plugin

DEFINES += DJVU_STATIC

PDF_PLUGIN_NAME   = release/libqpdfview_pdf.a
PS_PLUGIN_NAME    = release/libqpdfview_ps.a
DJVU_PLUGIN_NAME  = release/libqpdfview_djvu.a
IMAGE_PLUGIN_NAME = release/libqpdfview_image.a

PDF_PLUGIN_DEFINES      += HAS_POPPLER_14 HAS_POPPLER_18 HAS_POPPLER_20 HAS_POPPLER_22 HAS_POPPLER_24 HAS_POPPLER_26
#PDF_PLUGIN_DEFINES     += HAS_POPPLER_31 HAS_POPPLER_35
PDF_PLUGIN_INCLUDEPATH  += $($pkgconfig --cflags poppler-qt5 | sed 's|-I\/|\/|g')
PDF_PLUGIN_LIBS         += $($pkgconfig --libs poppler-qt5)

#PS_PLUGIN_LIBS         += $($pkgconfig --libs libspectre)
DJVU_PLUGIN_LIBS        += $($pkgconfig --libs ddjvuapi)
EOF


### clean up
test -f Makefile && (make distclean || true)
rm -f Makefile* translations/*.qm
rm -rf debug release

### compile translations
lrelease qpdfview.pro

### build qpdfview
$qmake qpdfview.pro
make -j4

