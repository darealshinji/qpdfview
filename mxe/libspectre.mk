# This file is part of MXE.
# See index.html for further information.

PKG             := libspectre
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 0.2.7
$(PKG)_CHECKSUM := e81b822a106beed14cf0fec70f1b890c690c2ffa150fa2eee41dc26518a6c3ec
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://libspectre.freedesktop.org/releases/$($(PKG)_FILE)
$(PKG)_DEPS     := gcc ghostscript cairo

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://libspectre.freedesktop.org/releases/' | \
    $(SED) -n 's:.*>LATEST-libspectre-::p' | \
    $(SED) -n 's:<.*::p'
endef

define $(PKG)_BUILD
    cd '$(1)' && autoreconf -f -i
    cd '$(1)' && ./configure $(MXE_CONFIGURE_OPTS) --enable-test
    $(MAKE) -C '$(1)' -j '$(JOBS)' install
    echo "Libs.private: `$(TARGET)-pkg-config --libs ghostscript`" >> '$(PREFIX)/$(TARGET)/lib/pkgconfig/libspectre.pc'
endef

