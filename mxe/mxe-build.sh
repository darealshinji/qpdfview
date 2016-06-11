#!/bin/sh -e

# helper script for static* mingw32 builds via MXE (https://github.com/mxe/mxe)
# (* can only build a libdjvu dll right now)

VERSION="0.4.16"

mupdfver="1.9a"
mupdfdir="mupdf-${mupdfver}-source"
mupdffile="${mupdfdir}.tar.gz"
mupdfsha256="8015c55f4e6dd892d3c50db4f395c1e46660a10b460e2ecd180a497f55bbc4cc"

djvuver1="3.5.25"
djvuver2="${djvuver1}.3"
djvudir="djvulibre-${djvuver1}"
djvufile="djvulibre-${djvuver2}.tar.gz"
djvusha256="898d7ed6dd2fa311a521baa95407a91b20a872d80c45e8245442d64f142cb1e0"

qpdf="qpdfview-git"

jobs=4

mxe_target="i686-w64-mingw32.static"
mxe_bin="$HOME/mxe/usr/bin"
mxe_qtbin="$HOME/mxe/usr/$mxe_target/qt/bin"
pkgconfig="${mxe_target}-pkg-config"

export PATH="$mxe_qtbin:$mxe_bin:$PATH"

# download
git clone --depth 1 "https://github.com/darealshinji/qpdfview" $qpdf
cd $qpdf
test -f $mupdffile || ( wget "http://mupdf.com/downloads/$mupdffile" && \
	(echo "$mupdfsha256 *$mupdffile" | sha256sum -c - || exit 1) )
test -f $djvufile || ( \
	wget "http://downloads.sourceforge.net/project/djvu/DjVuLibre/${djvuver1}/$djvufile" && \
	(echo "$djvusha256 *$djvufile" | sha256sum -c - || exit 1) )

# win32 settings
cat <<EOF > qpdfview_win32.pri
isEmpty(APPLICATION_VERSION):APPLICATION_VERSION = $VERSION

CONFIG += without_pkgconfig
CONFIG += without_magic
CONFIG += without_cups
CONFIG += without_synctex
CONFIG += without_signals
CONFIG += without_svg
CONFIG += with_fitz

CONFIG += static_pdf_plugin
CONFIG += static_ps_plugin
CONFIG += static_djvu_plugin
CONFIG += static_fitz_plugin
CONFIG += static_image_plugin

RESOURCES += icons_png.qrc

PDF_PLUGIN_NAME   = release/libqpdfview_pdf.a
PS_PLUGIN_NAME    = release/libqpdfview_ps.a
DJVU_PLUGIN_NAME  = release/libqpdfview_djvu.a
IMAGE_PLUGIN_NAME = release/libqpdfview_image.a
FITZ_PLUGIN_NAME  = release/libqpdfview_fitz.a

DJVU_PLUGIN_INCLUDEPATH += $djvudir/libdjvu
DJVU_PLUGIN_LIBS        += $djvudir/libdjvulibre.dll.a

PDF_PLUGIN_DEFINES      += HAS_POPPLER_14
PDF_PLUGIN_DEFINES      += HAS_POPPLER_18
PDF_PLUGIN_DEFINES      += HAS_POPPLER_20
PDF_PLUGIN_DEFINES      += HAS_POPPLER_22
PDF_PLUGIN_DEFINES      += HAS_POPPLER_24
PDF_PLUGIN_DEFINES      += HAS_POPPLER_26
#PDF_PLUGIN_DEFINES     += HAS_POPPLER_31
#PDF_PLUGIN_DEFINES     += HAS_POPPLER_35
PDF_PLUGIN_INCLUDEPATH  += $($pkgconfig --cflags poppler-qt4 | sed 's|-I\/|\/|g')
PDF_PLUGIN_LIBS         += $($pkgconfig --libs poppler-qt4)

PS_PLUGIN_INCLUDEPATH   += $($pkgconfig --cflags libspectre | sed 's|-I\/|\/|g')
PS_PLUGIN_LIBS          += $($pkgconfig --libs libspectre)

FITZ_PLUGIN_INCLUDEPATH += $mupdfdir/include
FITZ_PLUGIN_LIBS        += -L$mupdfdir/build/release -lmupdf -lmupdfthird
EOF

# clean up
test -f Makefile && make distclean
rm -f Makefile* lib*.a translations/*.qm icons/*.png
rm -rf $mupdfdir $djvudir debug release

# build MuPDF
tar xf $mupdffile
cp ../Makefile.mupdf $mupdfdir/Makefile.mxe
make -C $mupdfdir -j $jobs -f Makefile.mxe

# build djvulibre
tar xf $djvufile
cp ../Makefile.djvulibre $djvudir/Makefile.mxe
make -C $djvudir -j $jobs -f Makefile.mxe

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
make release || true

# problems with statically linking plugins
sed -i "s@qpdfview_win32_res.o release/libqpdfview_pdf.a release/libqpdfview_ps.a release/libqpdfview_djvu.a release/libqpdfview_fitz.a@qpdfview_win32_res.o release/libqpdfview_pdf.a $($pkgconfig --libs poppler-qt4) release/libqpdfview_ps.a $($pkgconfig --libs libspectre) release/libqpdfview_djvu.a $djvudir/libdjvulibre.dll.a release/libqpdfview_fitz.a -L$mupdfdir/build/release -Wl,--allow-multiple-definition -lmupdf -lmupdfthird@" Makefile.application.Release
make -f Makefile.application.Release

