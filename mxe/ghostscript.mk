# This file is part of MXE.
# See index.html for further information.

PKG             := ghostscript
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 9.19
$(PKG)_NODOTVER := $(subst .,,$($(PKG)_VERSION))
$(PKG)_CHECKSUM := f67acdcfcde1f86757ff3553cd719f12eac2d7681a0e96d8bdd1f40a0f47b45b
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.bz2
$(PKG)_URL      := https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs$($(PKG)_NODOTVER)/$($(PKG)_FILE)
$(PKG)_DEPS     := gcc dbus fontconfig freetype lcms libiconv libidn libjpeg-turbo libpaper libpng openjpeg tiff zlib

define $(PKG)_UPDATE
    $(WGET) -q -O- 'http://ghostscript.com/Releases.html' | \
    $(SED) -n 's:.*GPL_Ghostscript_::p' | \
    $(SED) -n 's:\.html.*::p'
endef

define $(PKG)_BUILD
    cd '$(1)' && rm -rf freetype jpeg lcms2 libpng openjpeg tiff zlib
    cd '$(1)' && $(LIBTOOLIZE) --force --copy --install
    cd '$(1)' && autoconf -f -i
    cd '$(1)' && ./configure $(MXE_CONFIGURE_OPTS) \
        --disable-contrib \
        --enable-threading \
        --enable-fontconfig \
        --enable-dbus \
        --enable-freetype \
        --disable-cups \
        --enable-openjpeg \
        --disable-gtk \
        --with-libiconv=gnu \
        --with-libidn \
        --with-libpaper \
        --with-system-libtiff \
        --with-ijs \
        --with-luratech \
        --with-jbig2dec \
        --with-omni \
        --without-x \
        --with-drivers=ALL \
        --with-memory-alignment=$(if $(filter x86_64-%,$(TARGET)),8,4)
    $(MAKE) -C '$(1)' -j 1 $(if $(BUILD_STATIC),gs.a,so)

    $(INSTALL) -d '$(PREFIX)/$(TARGET)/include/ghostscript'
    $(INSTALL) '$(1)/devices/gdevdsp.h' '$(PREFIX)/$(TARGET)/include/ghostscript/gdevdsp.h'
    $(INSTALL) '$(1)/base/gserrors.h' '$(PREFIX)/$(TARGET)/include/ghostscript/gserrors.h'
    $(INSTALL) '$(1)/psi/iapi.h' '$(PREFIX)/$(TARGET)/include/ghostscript/iapi.h'
    $(INSTALL) '$(1)/psi/ierrors.h' '$(PREFIX)/$(TARGET)/include/ghostscript/ierrors.h'

    $(INSTALL) -d '$(PREFIX)/$(TARGET)/bin'
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib'
    $(if $(BUILD_STATIC),\
        $(INSTALL) '$(1)/gs.a' '$(PREFIX)/$(TARGET)/lib/libgs.a',\
        $(INSTALL) '$(1)/sobin/libgs-9.dll' '$(PREFIX)/$(TARGET)/bin/libgs-9.dll' && \
        $(INSTALL) '$(1)/sobin/libgs.dll.a' '$(PREFIX)/$(TARGET)/lib/libgs.dll.a')

    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib/pkgconfig'
    (echo 'Name: ghostscript'; \
     echo 'Version: $($(PKG)_VERSION)'; \
     echo 'Description: Ghostscript library'; \
     echo 'Cflags: -I"$(PREFIX)/$(TARGET)/include/ghostscript"'; \
     echo 'Libs: -L"$(PREFIX)/$(TARGET)/lib" -lgs'; \
     echo 'Libs.private: -lm -lidn -liconv -lpaper -ltiff -lpng -ljpeg -lopenjp2 -llcms2 -lz -lwinspool';) \
     > '$(PREFIX)/$(TARGET)/lib/pkgconfig/ghostscript.pc'

    '$(TARGET)-gcc' \
        -W -Wall -Werror -pedantic `$(TARGET)-pkg-config --cflags ghostscript` \
        $(if $(BUILD_STATIC),-DGS_STATIC_LIB, ) \
        '$(2).c' -o '$(PREFIX)/$(TARGET)/bin/test-ghostscript.exe' \
        `$(TARGET)-pkg-config --libs ghostscript`
endef

