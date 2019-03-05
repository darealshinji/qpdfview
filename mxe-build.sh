#!/bin/bash
set -e

# helper script for mingw32 builds via MXE (https://github.com/mxe/mxe)
# requires MXE packages: djvulibre libspectre qt5 poppler

mxe_base="$HOME/dev/mxe"

VERSION="0.4.18beta1"

if [ "_$1" = "_x64" ]; then
  mxe_target="x86_64-w64-mingw32.static"
else
  mxe_target="i686-w64-mingw32.static"
fi

pc="${mxe_target}-pkg-config"
export PATH="$mxe_base/usr/$mxe_target/qt5/bin:$mxe_base/usr/bin:$PATH"

### checkout
rm -rf qpdfview-git
git clone --depth 100 "https://github.com/darealshinji/qpdfview" qpdfview-git
cd qpdfview-git
git checkout qpdfview-$VERSION

### win32 settings
cat <<EOF > qpdfview_win32.pri
APPLICATION_VERSION = $VERSION

CONFIG -= debug
CONFIG -= debug_and_release
CONFIG -= debug_and_release_target

CONFIG += without_pkgconfig
CONFIG += without_magic
CONFIG += without_cups
CONFIG += without_synctex
CONFIG += without_signals
CONFIG += static_resources
CONFIG += static_pdf_plugin
CONFIG += static_ps_plugin
CONFIG += static_djvu_plugin
CONFIG += static_image_plugin

DEFINES += HAS_POPPLER_14
DEFINES += HAS_POPPLER_18
DEFINES += HAS_POPPLER_20
DEFINES += HAS_POPPLER_22
DEFINES += HAS_POPPLER_24
DEFINES += HAS_POPPLER_26
DEFINES += HAS_POPPLER_31
DEFINES += HAS_POPPLER_35
DEFINES += DJVU_STATIC

POPPLER_VERSION    = $($pc --modversion poppler-qt5)
LIBSPECTRE_VERSION = $($pc --modversion libspectre)
DJVULIBRE_VERSION  = $($pc --modversion ddjvuapi)

PDF_PLUGIN_INCLUDEPATH  += $($pc --cflags-only-I poppler-qt5 | sed 's|-I\/|\/|g')
PDF_PLUGIN_LIBS         += $($pc --libs poppler-qt5 lcms2)

PS_PLUGIN_INCLUDEPATH   += $($pc --cflags-only-I libspectre | sed 's|-I\/|\/|g')
PS_PLUGIN_LIBS          += $($pc --libs libspectre)

DJVU_PLUGIN_INCLUDEPATH += $($pc --cflags-only-I ddjvuapi | sed 's|-I\/|\/|g')
DJVU_PLUGIN_LIBS        += $($pc --libs ddjvuapi)
EOF

### build qpdfview
lrelease qpdfview.pro
${mxe_target}-qmake-qt5 qpdfview.pro
make qmake_all
sed -i 's|-lqpdfview_|libqpdfview_|g' Makefile.application  # Qt bug
make -j4

