#!/bin/sh

# helper script for mingw32 builds on Msys

VERSION="0.4.16"

cat <<EOF > qpdfview_win32.pri
isEmpty(APPLICATION_VERSION):APPLICATION_VERSION = $VERSION

isEmpty(TARGET_INSTALL_PATH):TARGET_INSTALL_PATH = /usr/qpdfview
isEmpty(PLUGIN_INSTALL_PATH):PLUGIN_INSTALL_PATH = /usr/qpdfview
isEmpty(DATA_INSTALL_PATH):DATA_INSTALL_PATH = /usr/qpdfview
isEmpty(MANUAL_INSTALL_PATH):MANUAL_INSTALL_PATH = /usr/qpdfview
isEmpty(ICON_INSTALL_PATH):ICON_INSTALL_PATH = /usr/qpdfview/icons
isEmpty(LAUNCHER_INSTALL_PATH):LAUNCHER_INSTALL_PATH = /usr/qpdfview
isEmpty(APPDATA_INSTALL_PATH):APPDATA_INSTALL_PATH = /usr/qpdfview

DJVU_PLUGIN_INCLUDEPATH += /mingw32/include
DJVU_PLUGIN_LIBS += -ldjvulibre

PDF_PLUGIN_DEFINES += HAS_POPPLER_14
PDF_PLUGIN_DEFINES += HAS_POPPLER_18
PDF_PLUGIN_DEFINES += HAS_POPPLER_20
PDF_PLUGIN_DEFINES += HAS_POPPLER_22
PDF_PLUGIN_DEFINES += HAS_POPPLER_24
PDF_PLUGIN_DEFINES += HAS_POPPLER_26
#PDF_PLUGIN_DEFINES += HAS_POPPLER_31
#PDF_PLUGIN_DEFINES += HAS_POPPLER_35
PDF_PLUGIN_INCLUDEPATH += /mingw32/include/poppler/qt4 /mingw32/include/poppler
PDF_PLUGIN_LIBS += -lpoppler-qt4

PS_PLUGIN_INCLUDEPATH += /mingw32/include
PS_PLUGIN_LIBS += -lspectre
EOF

make distclean
rm -f Makefile* lib*.a translations/*.qm

for f in translations/*.ts; do lrelease $f; done

mkdir -p release/data
cp -f help/*.html translations/*.qm release/data

qmake CONFIG+="without_pkgconfig without_magic without_cups without_synctex without_signals static_pdf_plugin static_ps_plugin static_djvu_plugin static_image_plugin" qpdfview.pro
make release

cp -f release/*.a .
make release

g++ -s -mthreads -Wl,-subsystem,windows -Wl,--large-address-aware \
	-o release/qpdfview.exe object_script.qpdfview.Release \
	-L/mingw32/lib -lmingw32 -lqtmain \
	libqpdfview_pdf.a -lpoppler-qt4 \
	libqpdfview_ps.a -lspectre \
	libqpdfview_djvu.a -ldjvulibre \
	libqpdfview_image.a \
	-lQtDBus4 -lQtSvg4 -lQtSql4 -lQtXml4 -lQtGui4 -lQtCore4 && \
echo "Done."

