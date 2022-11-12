isEmpty(APPLICATION_VERSION):APPLICATION_VERSION = 0.5.0beta1

isEmpty(TARGET_INSTALL_PATH):TARGET_INSTALL_PATH = /usr/bin
isEmpty(PLUGIN_INSTALL_PATH):PLUGIN_INSTALL_PATH = /usr/lib/qpdfview
isEmpty(DATA_INSTALL_PATH):DATA_INSTALL_PATH = /usr/share/qpdfview
isEmpty(MANUAL_INSTALL_PATH):MANUAL_INSTALL_PATH = /usr/share/man/man1
isEmpty(ICON_INSTALL_PATH):ICON_INSTALL_PATH = /usr/share/icons/hicolor/scalable/apps
isEmpty(LAUNCHER_INSTALL_PATH):LAUNCHER_INSTALL_PATH = /usr/share/applications
isEmpty(APPDATA_INSTALL_PATH):APPDATA_INSTALL_PATH = /usr/share/metainfo
isEmpty(APP_DIR_DATA_PATH):APP_DIR_DATA_PATH = data

win32:include(qpdfview_win32.pri)
os2:include(qpdfview_os2.pri)

CONFIG += c++11
