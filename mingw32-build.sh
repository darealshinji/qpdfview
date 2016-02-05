#!/bin/sh

# helper script for mingw32 builds on Msys

VERSION="0.4.16"
include="/mingw32/include"

cat <<EOF > qpdfview_win32.pri
isEmpty(APPLICATION_VERSION):APPLICATION_VERSION = $VERSION

CONFIG += without_pkgconfig
CONFIG += without_magic
CONFIG += without_cups
CONFIG += without_synctex
CONFIG += without_signals
CONFIG += without_svg

RESOURCES += icons_png.qrc

PDF_PLUGIN_NAME   = qpdfview_pdf.dll
PS_PLUGIN_NAME    = qpdfview_ps.dll
DJVU_PLUGIN_NAME  = qpdfview_djvu.dll
IMAGE_PLUGIN_NAME = qpdfview_image.dll

DJVU_PLUGIN_INCLUDEPATH += $include
DJVU_PLUGIN_LIBS        += -ldjvulibre

PDF_PLUGIN_DEFINES      += HAS_POPPLER_14
PDF_PLUGIN_DEFINES      += HAS_POPPLER_18
PDF_PLUGIN_DEFINES      += HAS_POPPLER_20
PDF_PLUGIN_DEFINES      += HAS_POPPLER_22
PDF_PLUGIN_DEFINES      += HAS_POPPLER_24
PDF_PLUGIN_DEFINES      += HAS_POPPLER_26
#PDF_PLUGIN_DEFINES     += HAS_POPPLER_31
#PDF_PLUGIN_DEFINES     += HAS_POPPLER_35
PDF_PLUGIN_INCLUDEPATH  += $include/poppler/qt4 $include/poppler
PDF_PLUGIN_LIBS         += -lpoppler-qt4

PS_PLUGIN_INCLUDEPATH   += $include
PS_PLUGIN_LIBS          += -lspectre
EOF

test -f Makefile && make distclean
rm -f Makefile* lib*.a translations/*.qm icons/*.png

sed 's|\.svg|.png|g' icons.qrc > icons_png.qrc
for f in icons/*.svg; do
    rsvg-convert -o $(echo ${f%.*}).png $f
done

for f in translations/*.ts; do
    lrelease $f
done

mkdir -p release/data
cp -f help/*.html translations/*.qm release/data

qmake qpdfview.pro
make release
