#!/bin/bash
set -e
set -x

CMVER="3.13.1"
CMDIR="cmake-${CMVER}-Linux-x86_64"
POPVER="0.68.0"  # latest version that builds on Ubuntu 14.04
POPDIR="poppler-$POPVER"
GSVER="9.26"
GSDIR="ghostscript-$GSVER"
GSDIR2="gs926"
SPVER="0.2.8"
SPDIR="libspectre-$SPVER"
DJVVER="3.5.27"
DJVDIR="djvulibre-$DJVVER"
JOBS=6

export VERSION="0.4.18beta1"
export PKG_CONFIG_PATH="$PWD/build"
export PATH="$PWD/build/$CMDIR/bin:$PATH"

sudo apt install build-essential wget git fuse \
 libfontconfig1-dev libfreetype6-dev libidn11-dev libtiff5-dev libpng-dev \
 libjpeg-turbo8-dev zlib1g-dev libpaper-dev libdbus-1-dev libgs-dev \
 qt5-default qttools5-dev-tools qt5-qmake libqt5svg5-dev

rm -rf build
mkdir build
cd build


# djvulibre
wget -q -c "http://downloads.sourceforge.net/djvu/${DJVDIR}.tar.gz"
tar xf ${DJVDIR}.tar.gz
cd $DJVDIR

./configure --disable-static --disable-xmltools
make -j$JOBS -C libdjvu libdjvulibre.la
cp libdjvu/.libs/libdjvulibre.so.21 ..
cd ..

ln -s libdjvulibre.so.21 libdjvulibre.so
cat <<EOF> ddjvuapi.pc
Name: ddjvuapi
Description: DjVu Decoding API
Version: $DJVVER
Cflags: -I"$PWD/$DJVDIR"
Libs: -L"$PWD" -ldjvulibre
EOF


# poppler
wget -q -c "https://github.com/Kitware/CMake/releases/download/v$CMVER/${CMDIR}.tar.gz"
tar xf ${CMDIR}.tar.gz
wget -q -c "https://poppler.freedesktop.org/${POPDIR}.tar.xz"
tar xf ${POPDIR}.tar.xz
mkdir -p $POPDIR/build
cd $POPDIR/build
cmake .. -DENABLE_QT5=ON -DENABLE_LIBOPENJPEG=none
make -j$JOBS
cp libpoppler.so.79 ../..
cp qt5/src/libpoppler-qt5.so.1 ../..
cd ../..

ln -s libpoppler.so.79 libpoppler.so
ln -s libpoppler-qt5.so.1 libpoppler-qt5.so
cat <<EOF> poppler-qt5.pc
Name: poppler-qt5
Description: Qt5 bindings for poppler
Version: $POPVER
Libs: -L"$PWD" -lpoppler-qt5
Cflags: -I"$PWD/$POPDIR/qt5/src"
EOF


# ghostscript
wget -q -c "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/$GSDIR2/${GSDIR}.tar.gz"
tar xf ${GSDIR}.tar.gz
cd $GSDIR

rm -rf freetype jpeg libpng tiff zlib
CFLAGS="-O2 -fvisibility=hidden -DGSDLLEXPORT=\"__attribute__((visibility(\\\"default\\\")))\"" \
  ./configure --with-drivers=display --without-x --disable-gtk --disable-cups --disable-contrib --without-ijs
make -j$JOBS so-only
cp sobin/libgs.so.9 ..
cd ..


# libspectre
wget -q -c "http://libspectre.freedesktop.org/releases/${SPDIR}.tar.gz"
tar xf ${SPDIR}.tar.gz
cd $SPDIR

./configure --disable-static
make -j$JOBS
cp libspectre/.libs/libspectre.so.1 ..
cd ..

ln -s libspectre.so.1 libspectre.so
cat <<EOF> libspectre.pc
Name: libspectre
Description: libgs wrapper library
Version: $SPVER
Cflags: -I"$PWD/$SPDIR"
Libs: -L"$PWD" -lspectre
EOF


# qpdfview
git clone "https://github.com/darealshinji/qpdfview" qpdfview-git
cd qpdfview-git
git checkout qpdfview-$VERSION

lrelease qpdfview.pro
conf="static_resources with_lto static_pdf_plugin static_ps_plugin static_djvu_plugin static_image_plugin"
qmake CONFIG+="$conf" APPLICATION_VERSION="$VERSION" QMAKE_CXXFLAGS+="-std=gnu++11" qpdfview.pro
make -j$JOBS
cd ..


# bundle
mkdir -p appdir/usr/{bin,lib} appdir/usr/share/{applications,metainfo}
cp qpdfview-git/qpdfview appdir/usr/bin
cp qpdfview-git/miscellaneous/qpdfview.desktop appdir/usr/share/applications
cp qpdfview-git/miscellaneous/qpdfview.appdata.xml appdir/usr/share/metainfo
cp qpdfview-git/icons/qpdfview.svg appdir
cp lib*.so.* appdir/usr/lib
strip appdir/usr/bin/* appdir/usr/lib/*

wget -q -c -O deploy.AppImage "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
chmod a+x deploy.AppImage
./deploy.AppImage appdir/usr/share/applications/qpdfview.desktop -bundle-non-qt-libs -extra-plugins="imageformats/libqsvg.so"

doc="appdir/usr/share/doc"
mkdir -p $doc/{$POPDIR,$GSDIR,$SPDIR,$DJVDIR,qpdfview}
cp $POPDIR/README $doc/$POPDIR
cp $GSDIR/LICENSE $doc/$GSDIR
cp $SPDIR/README $doc/$SPDIR
cp $DJVDIR/COPYRIGHT $doc/$DJVDIR
cp qpdfview-git/CONTRIBUTORS qpdfview-git/COPYING $doc/qpdfview

wget -q -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod a+x appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage appdir

