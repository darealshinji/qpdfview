include(qpdfview.pri)

TARGET = qpdfview_pdf
TEMPLATE = lib
CONFIG += plugin
static_pdf_plugin:CONFIG += static

TARGET_SHORT = qpdfpdf
!isEmpty(PLUGIN_DESTDIR): DESTDIR = $$PLUGIN_DESTDIR

OBJECTS_DIR = objects-pdf
MOC_DIR = moc-pdf

HEADERS = sources/model.h sources/pdfmodel.h sources/annotationwidgets.h sources/formfieldwidgets.h
SOURCES = sources/pdfmodel.cpp sources/annotationwidgets.cpp sources/formfieldwidgets.cpp

QT += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets
lessThan(QT_MAJOR_VERSION, 6): QT += xml

!without_pkgconfig {
    greaterThan(QT_MAJOR_VERSION, 4) {
        pkg_config_exe = $$pkgConfigExecutable()
    } else {
        pkg_config_exe = pkg-config
    }

    poppler_qt_pkg = poppler-qt$${QT_MAJOR_VERSION}

    system($$pkg_config_exe --atleast-version=0.14 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_14
    system($$pkg_config_exe --atleast-version=0.18 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_18
    system($$pkg_config_exe --atleast-version=0.20.1 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_20
    system($$pkg_config_exe --atleast-version=0.22 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_22
    system($$pkg_config_exe --atleast-version=0.24 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_24
    system($$pkg_config_exe --atleast-version=0.26 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_26
    system($$pkg_config_exe --atleast-version=0.31 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_31
    system($$pkg_config_exe --atleast-version=0.35 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_35
    system($$pkg_config_exe --atleast-version=0.74 $${poppler_qt_pkg}):DEFINES += HAS_POPPLER_74

    CONFIG += link_pkgconfig
    PKGCONFIG += $${poppler_qt_pkg}
} else {
    DEFINES += $$PDF_PLUGIN_DEFINES
    INCLUDEPATH += $$PDF_PLUGIN_INCLUDEPATH
    LIBS += $$PDF_PLUGIN_LIBS
}

!static_pdf_plugin {
    target.path = $${PLUGIN_INSTALL_PATH}
    INSTALLS += target
}
