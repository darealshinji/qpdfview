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

CMVER="3.15.5"
CMDIR="cmake-${CMVER}-Linux-x86_64"
POPVER="0.68.0"  # latest version that builds on Ubuntu 14.04
POPDIR="poppler-$POPVER"
GSVER="9.50"
GSDIR="ghostscript-$GSVER"
GSDIR2="gs950"
SPVER="0.2.8"
SPDIR="libspectre-$SPVER"
DJVVER="3.5.27"
DJVDIR="djvulibre-$DJVVER"
JOBS=4
TOP="$PWD"

export VERSION="0.4.18"
export PKG_CONFIG_PATH="$PWD/build"
export PATH="$PWD/build/$CMDIR/bin:$PATH"

sudo apt-get install build-essential wget git fuse \
 libfontconfig1-dev libfreetype6-dev libidn11-dev libtiff5-dev libpng-dev \
 libjpeg-turbo8-dev zlib1g-dev libpaper-dev libdbus-1-dev libgs-dev \
 qt5-default qttools5-dev-tools qt5-qmake libqt5svg5-dev

mkdir -p build
cd build


# djvulibre
if [ ! -f ddjvuapi.pc ]; then
  rm -rf $DJVDIR libdjvulibre.so

  wget -q -c "http://downloads.sourceforge.net/djvu/${DJVDIR}.tar.gz"
  tar xf ${DJVDIR}.tar.gz
  cd $DJVDIR

  ./configure --disable-static --disable-xmltools
  make -j$JOBS -C libdjvu libdjvulibre.la
  cp -f libdjvu/.libs/libdjvulibre.so.21 ..
  cd ..

  ln -s libdjvulibre.so.21 libdjvulibre.so
  cat <<EOF > ddjvuapi.pc
Name: ddjvuapi
Description: DjVu Decoding API
Version: $DJVVER
Cflags: -I"$PWD/$DJVDIR"
Libs: -L"$PWD" -ldjvulibre
EOF
fi


# poppler
if [ ! -f poppler-qt5.pc ]; then
  rm -rf $POPDIR $CMDIR libpoppler.so libpoppler-qt5.so

  wget -q -c "https://github.com/Kitware/CMake/releases/download/v$CMVER/${CMDIR}.tar.gz"
  tar xf ${CMDIR}.tar.gz
  wget -q -c "https://poppler.freedesktop.org/${POPDIR}.tar.xz"
  tar xf ${POPDIR}.tar.xz

  mkdir -p $POPDIR/build
  cd $POPDIR/build
  cmake .. -DENABLE_QT5=ON -DENABLE_LIBOPENJPEG=none
  make -j$JOBS
  cp -f libpoppler.so.79 ../..
  cp qt5/src/libpoppler-qt5.so.1 ../..
  cd ../..

  ln -s libpoppler.so.79 libpoppler.so
  ln -s libpoppler-qt5.so.1 libpoppler-qt5.so
  cat <<EOF > poppler-qt5.pc
Name: poppler-qt5
Description: Qt5 bindings for poppler
Version: $POPVER
Libs: -L"$PWD" -lpoppler-qt5
Cflags: -I"$PWD/$POPDIR/qt5/src"
EOF
fi


# ghostscript
if [ ! -f libgs.so.9 ]; then
  rm -rf $GSDIR

  wget -q -c "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/$GSDIR2/${GSDIR}.tar.gz"
  tar xf ${GSDIR}.tar.gz
  cd $GSDIR

  rm -rf freetype jpeg libpng tiff zlib
  patch -p1 < "$TOP/gs-visibility.patch"
  CFLAGS="-O2 -fvisibility=hidden" ./configure --with-drivers=display --without-x --disable-gtk --disable-cups --disable-contrib --without-ijs
  make -j$JOBS so-only
  cp -f sobin/libgs.so.9 ..
  cd ..
fi


# libspectre
if [ ! -f libspectre.pc ]; then
  rm -rf $SPDIR libspectre.so

  wget -q -c "http://libspectre.freedesktop.org/releases/${SPDIR}.tar.gz"
  tar xf ${SPDIR}.tar.gz
  cd $SPDIR

  ./configure --disable-static
  make -j$JOBS
  cp -f libspectre/.libs/libspectre.so.1 ..
  cd ..

  ln -s libspectre.so.1 libspectre.so
  cat <<EOF > libspectre.pc
Name: libspectre
Description: libgs wrapper library
Version: $SPVER
Cflags: -I"$PWD/$SPDIR"
Libs: -L"$PWD" -lspectre
EOF
fi


# qpdfview
rm -rf qpdfview-build
test -e qpdfview-git || git clone --depth 100 "https://github.com/darealshinji/qpdfview" qpdfview-git
cp -r qpdfview-git qpdfview-build
cd qpdfview-build
#git checkout qpdfview-$VERSION

lrelease qpdfview.pro
conf="static_resources with_lto static_pdf_plugin static_ps_plugin static_djvu_plugin static_image_plugin"
qmake CONFIG+="$conf" APPLICATION_VERSION="$VERSION" QMAKE_CXXFLAGS+="-std=gnu++11" qpdfview.pro
make -j$JOBS
cd ..


# bundle
mkdir -p appdir/usr/{bin,lib} appdir/usr/share/{applications,metainfo}
cp qpdfview-build/qpdfview appdir/usr/bin
cp qpdfview-build/miscellaneous/qpdfview.desktop appdir/usr/share/applications
cp qpdfview-build/miscellaneous/qpdfview.appdata.xml appdir/usr/share/metainfo
cp qpdfview-build/icons/qpdfview.svg appdir
cp lib*.so.* appdir/usr/lib
strip appdir/usr/bin/* appdir/usr/lib/*

wget -q -c -O deploy.AppImage "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
patch_ai deploy.AppImage
chmod a+x deploy.AppImage
./deploy.AppImage appdir/usr/share/applications/qpdfview.desktop -verbose=2 -bundle-non-qt-libs -extra-plugins=iconengines,imageformats

doc="appdir/usr/share/doc"
mkdir -p $doc/{$POPDIR,$GSDIR,$SPDIR,$DJVDIR,qpdfview}
cp $POPDIR/README $doc/$POPDIR
cp $GSDIR/LICENSE $doc/$GSDIR
cp $SPDIR/README $doc/$SPDIR
cp $DJVDIR/COPYRIGHT $doc/$DJVDIR
cp qpdfview-git/CONTRIBUTORS qpdfview-git/COPYING $doc/qpdfview

wget -q -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
patch_ai appimagetool-x86_64.AppImage
chmod a+x appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage appdir

