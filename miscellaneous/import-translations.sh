#!/bin/bash -xe

set -o pipefail

source_dir=../translations-export
dest_dir=./translations

# trap 'rm -f "${temp_file}"' EXIT
# temp_file="$(mktemp)"

for source_file in ${source_dir}/*.po
do
    locale="$(basename ${source_file} .po)"
    dest_file="${dest_dir}/qpdfview_${locale}.ts"

    sed "s/^\"X-Generator:..*/\"X-Qt-Contexts: true\\\\n\"/" "${source_file}" \
    | sed -r "/^msgctxt \"[^Qq][^:]+\"/ s/^msgctxt \"([^Qq][^:|\"]+)|\"$/msgctxt \"qpdfview::\1/" \
    | lconvert -if po -i - -o "${dest_file}"
done

lupdate -no-obsolete ./qpdfview.pro

source_dir=../translations-export/help
dest_dir=./help

for source_file in ${source_dir}/*.po
do
    locale="$(basename ${source_file} .po)"
    dest_file="${dest_dir}/help_${locale}.html"

    po4a-translate --format xhtml --master "${dest_dir}/help.html" --master-charset utf-8 \
        --localized "${dest_file}" --localized-charset utf-8 \
        --po "${source_file}" --keep 0
done
