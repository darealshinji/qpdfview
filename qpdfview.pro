include(qpdfview.pri)

TEMPLATE = subdirs
CONFIG += ordered

!without_pdf {
    SUBDIRS += pdf-plugin.pro
    application.pro.depends = pdf-plugin.pro
}

!without_ps {
    SUBDIRS += ps-plugin.pro
    application.pro.depends = ps-plugin.pro
}

!without_djvu {
    SUBDIRS += djvu-plugin.pro
    application.pro.depends = djvu-plugin.pro
}

with_fitz {
    SUBDIRS += fitz-plugin.pro
    application.pro.depends = fitz-plugin.pro
}

!without_image {
    SUBDIRS += image-plugin.pro
    application.pro.depends = image-plugin.pro
}

SUBDIRS += application.pro

TRANSLATIONS += \
    translations/qpdfview_af.ts \
    translations/qpdfview_ast.ts \
    translations/qpdfview_az.ts \
    translations/qpdfview_be.ts \
    translations/qpdfview_ber.ts \
    translations/qpdfview_bg.ts \
    translations/qpdfview_bs.ts \
    translations/qpdfview_ca.ts \
    translations/qpdfview_cs.ts \
    translations/qpdfview_da.ts \
    translations/qpdfview_de.ts \
    translations/qpdfview_el.ts \
    translations/qpdfview_en_AU.ts \
    translations/qpdfview_en_GB.ts \
    translations/qpdfview_eo.ts \
    translations/qpdfview_es.ts \
    translations/qpdfview_eu.ts \
    translations/qpdfview_fa.ts \
    translations/qpdfview_fi.ts \
    translations/qpdfview_fr.ts \
    translations/qpdfview_gl.ts \
    translations/qpdfview_he.ts \
    translations/qpdfview_hi.ts \
    translations/qpdfview_hr.ts \
    translations/qpdfview_hu.ts \
    translations/qpdfview_id.ts \
    translations/qpdfview_it.ts \
    translations/qpdfview_ja.ts \
    translations/qpdfview_kk.ts \
    translations/qpdfview_ko.ts \
    translations/qpdfview_ku.ts \
    translations/qpdfview_ky.ts \
    translations/qpdfview_lt.ts \
    translations/qpdfview_lv.ts \
    translations/qpdfview_ms.ts \
    translations/qpdfview_my.ts \
    translations/qpdfview_nb.ts \
    translations/qpdfview_nds.ts \
    translations/qpdfview_oc.ts \
    translations/qpdfview_pl.ts \
    translations/qpdfview_pt.ts \
    translations/qpdfview_pt_BR.ts \
    translations/qpdfview_ro.ts \
    translations/qpdfview_ru.ts \
    translations/qpdfview_rue.ts \
    translations/qpdfview_sk.ts \
    translations/qpdfview_sr.ts \
    translations/qpdfview_sv.ts \
    translations/qpdfview_th.ts \
    translations/qpdfview_tr.ts \
    translations/qpdfview_ug.ts \
    translations/qpdfview_uk.ts \
    translations/qpdfview_uz.ts \
    translations/qpdfview_vi.ts \
    translations/qpdfview_zgh.ts \
    translations/qpdfview_zh_CN.ts \
    translations/qpdfview_zh_TW.ts
