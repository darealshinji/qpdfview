# Build qpdfview for Windows.
# Download MXE: git clone https://github.com/mxe/mxe
# Copy this file to mxe/plugins/apps.
# cd into mxe and build with:
#  make JOBS=4 qpdfview MXE_TARGETS="i686-w64-mingw32.static x86_64-w64-mingw32.static" MXE_PLUGIN_DIRS+=plugins/apps

PKG             := qpdfview
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 0.4.18beta1
$(PKG)_CHECKSUM := 36d97b88514be66ede66c30f68a8ad26b3e76fe39f27d3789c02775ce92859a2
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://launchpad.net/$(PKG)/trunk/$($(PKG)_VERSION)/+download/$($(PKG)_FILE)
$(PKG)_WEBSITE  := https://launchpad.net/qpdfview
$(PKG)_OWNER    := https://launchpad.net/~adamreichold
$(PKG)_DEPS     := cc djvulibre libspectre qtsvg qttools poppler

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://launchpad.net/qpdfview' | \
    $(SED) -n 's,.*/+download/qpdfview-\([0-9][^"]*\)\.tar.*,\1,p'
endef

define $(PKG)_BUILD
    (echo 'APPLICATION_VERSION = $($(PKG)_VERSION)'; \
     echo 'CONFIG -= debug debug_and_release debug_and_release_target'; \
     echo 'CONFIG += without_pkgconfig without_magic without_cups without_synctex without_signals'; \
     echo 'CONFIG += static_resources static_pdf_plugin static_ps_plugin static_djvu_plugin static_image_plugin'; \
     echo 'DEFINES += HAS_POPPLER_14 HAS_POPPLER_18 HAS_POPPLER_20 HAS_POPPLER_22 HAS_POPPLER_24 HAS_POPPLER_26 HAS_POPPLER_31 HAS_POPPLER_35'; \
     echo 'DEFINES += DJVU_STATIC'; \
     echo 'POPPLER_VERSION = $(poppler_VERSION)'; \
     echo 'LIBSPECTRE_VERSION = $(libspectre_VERSION)'; \
     echo 'DJVULIBRE_VERSION = $(djvulibre_VERSION)'; \
     echo "PDF_PLUGIN_INCLUDEPATH += `$(TARGET)-pkg-config --cflags-only-I poppler-qt5 | $(SED) 's|-I\/|\/|g'`"; \
     echo "PDF_PLUGIN_LIBS += `$(TARGET)-pkg-config --libs poppler-qt5 lcms2`"; \
     echo "PS_PLUGIN_INCLUDEPATH += `$(TARGET)-pkg-config --cflags-only-I libspectre | $(SED) 's|-I\/|\/|g'`"; \
     echo "PS_PLUGIN_LIBS += `$(TARGET)-pkg-config --libs libspectre`"; \
     echo "DJVU_PLUGIN_INCLUDEPATH += `$(TARGET)-pkg-config --cflags-only-I ddjvuapi | $(SED) 's|-I\/|\/|g'`"; \
     echo "DJVU_PLUGIN_LIBS += `$(TARGET)-pkg-config --libs ddjvuapi`";) \
     > '$(SOURCE_DIR)/qpdfview_win32.pri'

    cd '$(BUILD_DIR)' && $(TARGET)-qmake-qt5 '$(SOURCE_DIR)/qpdfview.pro'
    $(MAKE) -j '$(JOBS)' -C '$(BUILD_DIR)' qmake_all
    $(SED) -i 's|-lqpdfview_|libqpdfview_|g' '$(BUILD_DIR)/Makefile.application' # Qt bug; fixed in upcoming release

    cd '$(SOURCE_DIR)/translations' && '$(PREFIX)/$(TARGET)/qt5/bin/lrelease' *.ts
    $(MAKE) -j '$(JOBS)' -C '$(BUILD_DIR)'

    cp '$(BUILD_DIR)/qpdfview.exe' '$(PREFIX)/$(TARGET)/bin/'
endef

$(PKG)_BUILD_SHARED =
