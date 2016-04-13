#!/bin/sh

# helper script for mingw32 builds on Msys

# pacman -S wget mingw-w64-i686-qt5 mingw-w64-i686-poppler mingw-w64-i686-libspectre mingw-w64-i686-djvulibre mingw-w64-i686-librsvg

VERSION="0.4.16"
include="/mingw32/include"
mupdfver="1.8"
mupdfdir="mupdf-${mupdfver}-source"
mupdfmd5="3205256d78d8524d67dd2a47c7a345fa"

cat <<EOF > qpdfview_win32.pri
isEmpty(APPLICATION_VERSION):APPLICATION_VERSION = $VERSION

CONFIG += without_pkgconfig
CONFIG += without_magic
CONFIG += without_cups
CONFIG += without_synctex
CONFIG += without_signals
CONFIG += without_svg
CONFIG += with_fitz

RESOURCES += icons_png.qrc

PDF_PLUGIN_NAME   = qpdfview_pdf.dll
PS_PLUGIN_NAME    = qpdfview_ps.dll
DJVU_PLUGIN_NAME  = qpdfview_djvu.dll
IMAGE_PLUGIN_NAME = qpdfview_image.dll
FITZ_PLUGIN_NAME  = qpdfview_fitz.dll

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
PDF_PLUGIN_INCLUDEPATH  += $include/poppler/qt5 $include/poppler
PDF_PLUGIN_LIBS         += -lpoppler-qt5

PS_PLUGIN_INCLUDEPATH   += $include
PS_PLUGIN_LIBS          += -lspectre

FITZ_PLUGIN_INCLUDEPATH += $mupdfdir/include
FITZ_PLUGIN_LIBS        += $mupdfdir/build/release/libmupdf.a -lfreetype -ljpeg -lz
FITZ_PLUGIN_LIBS        += $mupdfdir/build/release/libopenjpeg.a
FITZ_PLUGIN_LIBS        += $mupdfdir/build/release/libjbig2dec.a
EOF

# clean up
test -f Makefile && make distclean
rm -f Makefile* lib*.a translations/*.qm icons/*.png
rm -rf $mupdfdir release

# build MuPDF
test -f mupdf-${mupdfver}-source.tar.gz || (\
    wget http://mupdf.com/downloads/mupdf-${mupdfver}-source.tar.gz && \
	(echo "$mupdfmd5 *mupdf-${mupdfver}-source.tar.gz" | md5sum.exe -c - || exit 1))
tar xf mupdf-${mupdfver}-source.tar.gz
for l in mupdf openjpeg jbig2dec; do
    make -C $mupdfdir build/release/lib${l}.a build=release
done

# convert icons
sed 's|\.svg|.png|g' icons.qrc > icons_png.qrc
for f in icons/*.svg; do
    rsvg-convert -o $(echo ${f%.*}).png $f
done

# compile translations
lrelease qpdfview.pro

# copy files
mkdir -p release/data
cp help/*.html translations/*.qm release/data
cp icons/qpdfview_win32.ico release/qpdfview.ico

# build qpdfview
qmake qpdfview.pro
make release
