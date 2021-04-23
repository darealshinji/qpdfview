#!/bin/bash -xe

lupdate -no-obsolete ./qpdfview.pro

source_file=./translations/qpdfview_ast.ts
dest_file=../translations-export/qpdfview.pot

lconvert -i "${source_file}" -o "${dest_file}" -of pot
sed -i "s/^msgctxt \"qpdfview::/msgctxt \"/" "${dest_file}"

source_file=./help/help.html
dest_file=../translations-export/help/help.pot

po4a-gettextize --format xhtml --master "${source_file}" --master-charset utf-8 \
    --po "${dest_file}" --package-name "qpdfview" --package-version "1.0" --copyright-holder "Adam Reichold" \
    --msgid-bugs-address "launchpad-translators@lists.launchpad.net"
