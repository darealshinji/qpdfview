# Download MXE: git clone https://github.com/mxe/mxe
# Copy this file to mxe/plugins/apps.
# cd into mxe and build with:
#  make JOBS=4 qpdfview MXE_TARGETS=x86_64-w64-mingw32.static MXE_PLUGIN_DIRS+=plugins/apps

PKG             := qpdfview
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 0.5.0
$(PKG)_VERSION_ := 0.5
$(PKG)_CHECKSUM := 44efc440a461cbdd757a9b396f1461ee7a2f4364e81df55bd0221f910219be99
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION_)
$(PKG)_FILE     := $($(PKG)_SUBDIR).tar.gz
$(PKG)_URL      := https://launchpad.net/$(PKG)/trunk/$($(PKG)_VERSION)/+download/$($(PKG)_FILE)
$(PKG)_WEBSITE  := https://launchpad.net/qpdfview
$(PKG)_OWNER    := https://launchpad.net/~adamreichold
$(PKG)_DEPS     := cc djvulibre libspectre poppler-qt5 qtsvg qttools

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://launchpad.net/qpdfview' | \
    $(SED) -n 's,.*/+download/qpdfview-\([0-9][^"]*\)\.tar.*,\1,p'
endef

define $(PKG)_BUILD
    (echo 'CONFIG -= debug debug_and_release debug_and_release_target'; \
     echo 'CONFIG += without_magic without_cups without_signals'; \
     echo 'CONFIG += static_resources static_pdf_plugin static_ps_plugin static_djvu_plugin static_image_plugin';) \
     > '$(SOURCE_DIR)/qpdfview_win32.pri'

    cd '$(BUILD_DIR)' && $(TARGET)-qmake-qt5 '$(SOURCE_DIR)/qpdfview.pro'
    $(MAKE) -j '$(JOBS)' -C '$(BUILD_DIR)' qmake_all
    $(SED) -i 's|-lqpdfview_|libqpdfview_|g' '$(BUILD_DIR)/Makefile.application' # workaround for bug

    '$(PREFIX)/$(TARGET)/qt5/bin/lrelease' '$(SOURCE_DIR)/qpdfview.pro'
    $(MAKE) -j '$(JOBS)' -C '$(BUILD_DIR)'

    cp '$(BUILD_DIR)/qpdfview.exe' '$(PREFIX)/$(TARGET)/bin/'
endef

$(PKG)_BUILD_SHARED =

