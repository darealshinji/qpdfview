#!/bin/bash

function patch_ai ()
{
  wget -q -c "https://raw.githubusercontent.com/darealshinji/code-snippets/master/hexedit.c"
  gcc -O2 hexedit.c
  ./a.out --mode=set --offset=0x08 --char=0x00 --file="$1"
  ./a.out --mode=set --offset=0x09 --char=0x00 --file="$1"
  ./a.out --mode=set --offset=0x0A --char=0x00 --file="$1"
}

set -e
set -x

POPVER="23.04.0"
POPDIR="poppler-$POPVER"
GSVER="10.01.1"
GSDIR="ghostscript-$GSVER"
GSDIR_="gs10011"
SPVER="0.2.8"
SPDIR="libspectre-$SPVER"
DJVVER="3.5.28"
DJVDIR="djvulibre-$DJVVER"

JOBS=4

TOP="$PWD"

VERSION="0.5.0"
VERSION_="0.5"
QPDFDIR="qpdfview-${VERSION_}"

export PKG_CONFIG_PATH="$TOP/usr/lib/pkgconfig"
export LD_LIBRARY_PATH="$TOP/usr/lib"

sudo apt install \
  build-essential \
  wget \
  fuse \
  cmake \
  libfontconfig1-dev \
  libfreetype6-dev \
  libidn11-dev \
  libtiff5-dev \
  libpng-dev \
  libjpeg-turbo8-dev \
  zlib1g-dev \
  libpaper-dev \
  libdbus-1-dev \
  libopenjp2-7-dev \
  libcairo2-dev \
  liblcms2-dev \
  libboost-dev \
  libcups2-dev \
  qtbase5-dev \
  qttools5-dev-tools \
  libqt5svg5-dev


# djvulibre
if [ ! -f usr/lib/pkgconfig/ddjvuapi.pc ]; then
  rm -rf $DJVDIR
  wget -q -c "http://downloads.sourceforge.net/djvu/${DJVDIR}.tar.gz"
  tar xf ${DJVDIR}.tar.gz
  cd $DJVDIR

  ./configure --prefix="$TOP/usr" --disable-static --disable-xmltools
  make -j $JOBS
  make install
  cd ..
fi


# poppler
if [ ! -f usr/lib/pkgconfig/poppler-qt5.pc ]; then
  rm -rf $POPDIR
  wget -q -c "https://poppler.freedesktop.org/${POPDIR}.tar.xz"
  tar xf ${POPDIR}.tar.xz

  mkdir -p $POPDIR/build
  cd $POPDIR/build
  cmake .. -DCMAKE_INSTALL_PREFIX="$TOP/usr" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_QT5=ON \
    -DENABLE_QT6=OFF \
    -DBUILD_GTK_TESTS=OFF \
    -DBUILD_QT5_TESTS=OFF \
    -DBUILD_QT6_TESTS=OFF \
    -DBUILD_CPP_TESTS=OFF
  make -j $JOBS
  make install
  cd ../..
fi


# ghostscript
if [ ! -f usr/lib/pkgconfig/ghostscript.pc ]; then
  rm -rf $GSDIR
  wget -q -c "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/$GSDIR_/${GSDIR}.tar.xz"
  tar xf ${GSDIR}.tar.xz
  cd $GSDIR

  rm -rf freetype jpeg libpng tiff openjpeg zlib
  ./configure --prefix="$TOP/usr" --without-x --disable-gtk
  make -j $JOBS so-only
  make soinstall
  cd ..

  cat <<EOF > usr/lib/pkgconfig/ghostscript.pc
Name: ghostscript
Version: $GSVER
Description: Ghostscript library
Cflags: -I"$TOP/usr/include/ghostscript"
Libs: -L"$TOP/usr/lib" -lgs
EOF
fi


# libspectre
if [ ! -f usr/lib/pkgconfig/libspectre.pc ]; then
  rm -rf $SPDIR
  wget -q -c "http://libspectre.freedesktop.org/releases/${SPDIR}.tar.gz"
  tar xf ${SPDIR}.tar.gz
  cd $SPDIR

  CFLAGS="-O2 -I$TOP/usr/include" LDFLAGS="-L$TOP/usr/lib -s" \
  ./configure --prefix="$TOP/usr" --disable-static
  make -j $JOBS
  make install
  cd ..
fi


# qpdfview
if [ ! -d $QPDFDIR ]; then
  wget -q -c https://launchpad.net/qpdfview/trunk/$VERSION/+download/${QPDFDIR}.tar.gz
  tar xf ${QPDFDIR}.tar.gz
fi
cd $QPDFDIR
lrelease qpdfview.pro
qmake CONFIG+="static_resources static_pdf_plugin static_ps_plugin static_djvu_plugin static_image_plugin" qpdfview.pro
make -j $JOBS
cd ..


# bundle
rm -rf appdir
mkdir -p appdir/usr/{bin,lib} appdir/usr/share/{applications,metainfo}
cp $QPDFDIR/qpdfview appdir/usr/bin
cp $QPDFDIR/miscellaneous/qpdfview.desktop appdir/usr/share/applications
cp $QPDFDIR/miscellaneous/qpdfview.appdata.xml appdir/usr/share/metainfo
cp $QPDFDIR/icons/qpdfview.svg appdir

wget -q -c -O deploy.AppImage "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
#patch_ai deploy.AppImage
chmod a+x deploy.AppImage
./deploy.AppImage appdir/usr/share/applications/qpdfview.desktop -verbose=2 -bundle-non-qt-libs -extra-plugins=iconengines,imageformats

doc="appdir/usr/share/doc"
mkdir -p $doc/{$POPDIR,$GSDIR,$SPDIR,$DJVDIR,qpdfview}
cp $DJVDIR/COPYRIGHT $doc/$DJVDIR
cp $GSDIR/doc/COPYING $doc/$GSDIR
cp $POPDIR/COPYING $doc/$POPDIR
cp $SPDIR/COPYING $doc/$SPDIR
cp $QPDFDIR/{CONTRIBUTORS,COPYING,CHANGES} $doc/qpdfview

wget -q -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
#patch_ai appimagetool-x86_64.AppImage
chmod a+x appimagetool-x86_64.AppImage
VERSION=$VERSION ./appimagetool-x86_64.AppImage appdir

