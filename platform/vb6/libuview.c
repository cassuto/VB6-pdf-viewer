/** @file
 * uViewer - libuview implements.
 */

/*
 *  uViewer (a tiny document viewer) is Copyleft (C) 2017
 *
 *  This project is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public License(GPL)
 *  as published by the Free Software Foundation; either version 2.1
 *  of the License, or (at your option) any later version.
 *
 *  This project is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 */

/*******************************************************************************
*   Header Files                                                               *
*******************************************************************************/
#include <stdlib.h>
#include <string.h>
#include "uview/fitz.h"
#include "uview/pdf.h"
#include "libuview.h"

/*******************************************************************************
*   Types and structures                                                       *
*******************************************************************************/
typedef struct uview_s uview_t;

typedef VBF(char*)(*fnEventInputBox)(uview_t *p, const char *currentText, int retry);
typedef VBF(int)  (*fnEventCheckBox)(uview_t *p, int nopts, char *opts[], int *nvals, char *vals[]);
typedef VBF(void) (*fnEventRepaintView)(uview_t *p);
typedef VBF(void) (*fnEventGotoPage)(uview_t *p, int page);
typedef VBF(void) (*fnEventGotoURL)(uview_t *p, const char *url);
typedef VBF(void) (*fnEventCursor)(uview_t *p, int cursor);
typedef VBF(void) (*fnEventWarn)(uview_t *p, const char *msg);

typedef enum event_type_e {
    EVENT_UNKNOWN = 0,
    EVENT_SHOW_INPUTBOX,
    EVENT_SHOW_CHECKBOX,
    EVENT_REPAINT_VIEW,
    EVENT_GOTO_PAGE,
    EVENT_GOTO_URL,
    EVENT_CURSOR,
    EVENT_WARN,
    EVENT_INT32 = 0xffffffff // hack: ensure 32bit
} event_type_t;

typedef enum cursor_e {
    NORMAL = 0, ARROW, HAND, WAIT, CARET
} cursor_t ;

typedef enum defferred_e {
    PDFAPP_OUTLINE_DEFERRED = 1,
    PDFAPP_OUTLINE_LOAD_NOW = 2
} defferred_t;

typedef struct uview_s {
    unsigned        magic;
    fz_context      *uv;
	fz_document     *doc;
	fz_matrix       ctm;
	fz_colorspace   *colorspace;
	char            *docpath;
    int             page_count;
    fz_outline      *outline;
    int             outline_deferred;
    float           rotate;

    fnEventInputBox cb_event_inputbox;
    fnEventCheckBox cb_event_checkbox;
    fnEventRepaintView cb_event_repaint_view;
    fnEventGotoPage cb_event_goto_page;
    fnEventGotoURL  cb_event_goto_url;
    fnEventCursor   cb_event_cursor;
    fnEventWarn     cb_event_warn;
} uview_t;

typedef struct pixmap_s {
    int magic;
    int w, h;
    int n;
    char *samples;
    fz_pixmap *p;
    fz_page *page;
    fz_link *page_links;
    fz_rect page_bbox;
    int pageno;
    int incomplete;
    double resolution;
} pixmap_t;

typedef struct errinfo_s {
    const char *msg_short;
    const char *msg_detail;
    const char *definition;
    int code;
} errinfo_t;

/*******************************************************************************
*   Exported Functions                                                         *
*******************************************************************************/
DECL(int)           uv_validate(int, int);
DECL(uview_t *)     uv_create_context();
DECL(void)          uv_drop_context(uview_t *);
DECL(int)           uv_open_file(uview_t *p, const char *fn, int flags);
DECL(int)           uv_register_font(uview_t *p, const char *fn);
DECL(int)           uv_render_pixmap(uview_t *p, int page, pixmap_t **pix);
DECL(int)           uv_pixmap_fill_docinfo(uview_t *p, pixmap_t *pix);
DECL(int)           uv_pixmap_getinfos(uview_t *p, pixmap_t *pix, int *w, int *h, int *n, char **samples);
DECL(void)          uv_drop_pixmap(uview_t *p, pixmap_t *pix);
DECL(int)           uv_get_page_count(uview_t *p);
DECL(void)          uv_scale(uview_t *p, float sx, float sy);
DECL(void)          uv_rotate(uview_t *p, float th);
DECL(int)           uv_convert_2_bpp(uview_t *p, pixmap_t *pix, char **out);
DECL(int)           uv_drop_mem(uview_t *p, char *mem);
DECL(int)           uv_strlen(const char *str);
DECL(int)           uv_strcpy(char *src, const char *dest);
DECL(int)           uv_error_msg(int rc, const char **msg);
DECL(int)           uv_error_def(int rc, const char **def);
DECL(int)           uv_register_event(uview_t *p, event_type_t t, void *pf);
DECL(int)           uv_mouse_event(uview_t *p, pixmap_t *pix, int x, int y, int btn, int modifiers, int state);

/*******************************************************************************
*   Internal Functions                                                         *
*******************************************************************************/
static VBF(char*) dummy_p_cs_n_rc(uview_t *, const char *, int);
static VBF(void)  dummy_p_cs_n(uview_t *, const char *, int);
static VBF(int)   dummy_p_n_apc_pn_apc(uview_t *p, int n, char *apc0[], int *pn, char *apc1[]);
static VBF(void)  dummy_p_cs(uview_t *, const char *);
static VBF(void)  dummy_p(uview_t *);
static VBF(void)  dummy_p_n(uview_t *, int);

/*******************************************************************************
*   Macro Definitions                                                         *
*******************************************************************************/
#define DEBUG_UV 1

#define POST_EVENT(p, name, param) p->cb_event_##name param

#ifndef MAX
# define MAX(n1, n2) (n1 > n2 ? n1 : n2)
# define MIN(n1, n2) (n1 < n2 ? n1 : n2)
#endif

/*******************************************************************************
*   Error infomations                                                          *
*******************************************************************************/
static const errinfo_t g_errorsDescriptors[] = {
#   include <errors-generated.h>
    {"Unknown", "Unknown status", "UNKNOWN", 0}
};

////////////////////////////////////////////////////////////////////////////////

/**
 * Stubs, void functions that do nothing.
 * @param p Pointer to the viewer context.
 * @param cs a const char pointer.
 * @param apc an array of pointers to char.
 * @param n an integer number pointer.
 * @param pn a pointer to the integer number.
 */

static VBF(char*)dummy_p_cs_n_rc(uview_t *p, const char *cs, int n) {
    (void)p;
    (void)cs;
    (void)n;
    return NULL;
}

static VBF(void) dummy_p_cs_n(uview_t *p, const char *cs, int n) {
    (void)p;
    (void)cs;
    (void)n;
}

static VBF(int) dummy_p_n_apc_pn_apc(uview_t *p, int n, char *apc0[], int *pn, char *apc1[]) {
    (void)p;
    (void)n;
    (void)apc0;
    (void)pn;
    (void)apc1;
    return 0;
}

static VBF(void) dummy_p_cs(uview_t *p, const char *cs) {
    (void)p;
    (void)cs;
}

static VBF(void) dummy_p(uview_t *p) {
    (void)p;
}

static VBF(void) dummy_p_n(uview_t *p, int n) {
    (void)p;
    (void)n;
}

/**
 * Check the version for which we required.
 * @param major     The majority version.
 * @param minor     The minority version.
 * @return OK_SUCCEEDED.
 * @return ERR_FAILED.
 */
DECL(int) uv_validate(int major, int minor) {
    return (major ==0 && minor == 0) ? OK_SUCCEEDED : ERR_FAILED;
}

/**
 * Create a new context with memory allocated.
 * @return a pointer to the context area.
 * @return NULL if failed.
 */
DECL(uview_t *) uv_create_context() {
    uview_t *n = (uview_t *)malloc(sizeof(*n));
    if (!n) return n;
    
    /*
     set the default data and create the context
     to hold the exception stack and various caches.
     */
    n->magic = UVIEW_MAGIC;
    n->uv = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
    if (!n->uv) {
        free(n);
        return NULL;
    }

    n->doc = NULL;
    memset(&n->ctm, 0, sizeof(n->ctm));
#if defined(_WIN32) || defined(_WIN64)
    n->colorspace = fz_device_bgr(n->uv); // BGR little endian
#else
    n->colorspace = fz_device_rgb(n->uv); // RGB big endian
#endif

    n->cb_event_inputbox = dummy_p_cs_n_rc;
    n->cb_event_checkbox = dummy_p_n_apc_pn_apc;
    n->cb_event_repaint_view = dummy_p;
    n->cb_event_goto_page = dummy_p_n;
    n->cb_event_goto_url = dummy_p_cs;
    n->cb_event_cursor = dummy_p_n;
    n->cb_event_warn = dummy_p_cs;
    (void)dummy_p_cs_n;

    n->outline = NULL;
    n->outline_deferred = 0;
    n->docpath = NULL;
    n->rotate = 0;

    /*
     Register the default file types to handle.
     */
    fz_try(n->uv)
        fz_register_document_handlers(n->uv);
    fz_catch(n->uv) {
        MSG("cannot register document handlers: %s\n", fz_caught_message(n->uv));
        fz_drop_context(n->uv);
        free(n);
        return NULL;
    }

    return n;
}

/**
 * Destroy the context and release the memory.
 * @param p Pointer to the target context.
 */
DECL(void) uv_drop_context(uview_t *p) {
    CHECKR_STRICT_PTR(p);
    CHECKR_MAGIC(p->magic);
    
    /* Clean up. */
    if (p->doc)
        fz_drop_document(p->uv, p->doc);
    if (p->outline)
        fz_drop_outline(p->uv, p->outline);
    if (p->docpath)
        fz_free(p->uv, p->docpath);
    if (p->uv)
        fz_drop_context(p->uv);
    
    p->magic = 0xbadbeef; // invalid magic
    free(p);
}

/**
 * Register a extend font module.
 * the module is usually a dynamic-linking library or
 * a shared object extended with .so.
 * @param fn Filename of module
 * @return status code
 */
DECL(int) uv_register_font(uview_t *p, const char *fn) {
    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(fn);
    CHECK_MAGIC(p->magic);

    return fz_register_extern_font(p->uv, fn) ? ERR_FAILED : OK_SUCCEEDED;
}

/**
 * Get the number of pages total.
 * @param p Pointer to the viewer context.
 * @return 0 if failed.
 * @return > 0 the number expected.
 */
DECL(int) uv_get_page_count(uview_t *p) {
    CHECK_STRICT_PTR(p);
    CHECK_MAGIC(p->magic);

    if (!p->doc)
        return 0;
    return p->page_count;
}

/**
 * Scale the page.
 * This function will not refresh the data in samples,
 * and only change a matrix in inner structure.
 * @param p Pointer to the viewer context.
 * @param sx The percentage of x.
 * @param sy The percentage of y.
 */
DECL(void) uv_scale(uview_t *p, float sx, float sy) {
    CHECKR_STRICT_PTR(p);
    CHECKR_MAGIC(p->magic);

    fz_scale(&p->ctm, sx / 100, sy / 100);
}

/**
 * Rotate the page.
 * This function will not refresh the data in samples,
 * and only change a matrix in inner structure.
 * @param p Pointer to the viewer context.
 * @param th Angle in degrees.
 */
DECL(void) uv_rotate(uview_t *p, float th) {
    CHECKR_STRICT_PTR(p);
    CHECKR_MAGIC(p->magic);

    fz_rotate(&p->ctm, th);
    p->rotate = th;
}

/**
 * Convert the 4-bytes samples into 2 bytes (per pixel).
 * BPP = Bytes Per Pixel.
 * This function will allocated a new memory, so we should
 * drop it by calling uv_drop_mem().
 * @param p Pointer to the viewer context.
 * @param pix Pointer to the pixmap.
 * @param out Where to store the pointer of new samples.
 * @return status code.
 */
DECL(int) uv_convert_2_bpp(uview_t *p, pixmap_t *pix, char **out) {
    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(pix);
    CHECK_STRICT_PTR(out);
    CHECK_MAGIC(p->magic);

    if (pix->magic != PIXMAP_MAGIC) {
        *out = NULL;
        return ERR_INVALID_MAGIC;
    }

    int i = pix->w * pix->h;
    /*unsigned*/ char *color = malloc(i*4);
    /*unsigned*/ char *s = pix->samples;
    /*unsigned*/ char *d = color;

    if (!color) {
        *out = NULL;
        return ERR_ALLOC_MEMORY;
    }

    for (; i > 0 ; i--) {
        d[2] = d[1] = d[0] = *s++;
        d[3] = *s++;
        d += 4;
    }

    *out = color;
    return OK_SUCCEEDED;
}

/**
 * Release the memory that was allocated by free().
 * VERY IMPORTANT! this will NOT destructor or uninitialize the context
 * object in memory specified if it has an object. In normal this
 * function is seldom used except uv_convert_2_bpp() or other misces.
 * @return status code.
 */
DECL(int) uv_drop_mem(uview_t *p, char *mem) {
    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(mem);
    CHECK_MAGIC(p->magic);

    free(mem);
    return OK_SUCCEEDED;
}

/**
 * This function is only used by Visual Basic.
 * Get the length of a string that was terminated with '\0'.
 * @param str Pointer to the target string.
 * @return 0 if failed.
 * @return > 0 the length of string.
 */
DECL(int) uv_strlen(const char *str) {
    if (!str)
        return 0;
    return strlen(str);
}

/**
 * This function is only used by Visual Basic.
 * Copy a string, which was terminated with '\0', to destination
 * memory.
 * The destination memory should have enough space to store the source
 * string.
 * @param dest Pointer to the target memory.
 * @param src Pointer to the source string.
 * @return status code
 */
DECL(int) uv_strcpy(char *dest, const char *src) {
    CHECK_STRICT_PTR(src);
    CHECK_STRICT_PTR(dest);
    
    strcpy(dest, src);
    return OK_SUCCEEDED;
}


/**
 * Get the infomation of error according to the status code.
 * @param rc status code.
 * @return 0 if the code is not found.
 * @return Pointer to the error_info_t structure.
 */
static const errinfo_t *geterr(int rc) {
    unsigned i;
    int matched = 0;

    for(i=0;i<GET_ELEMENTS(g_errorsDescriptors)-1;i++) {
        if(g_errorsDescriptors[i].code == rc) {
            matched = 1;
            break;
        }
    }

    if(matched)
        return &g_errorsDescriptors[i];
    else {
        return &g_errorsDescriptors[GET_ELEMENTS(g_errorsDescriptors)-2];
    }
}

/**
 * Get the error message according to the status code.
 * @param rc status code.
 * @param msg Where to store the pointer of message text.
 * @return OK_SUCCEEDED.
 * @return else if failed.
 */
DECL(int) uv_error_msg(int rc, const char **msg) {
    CHECK_STRICT_PTR(msg);
   
    *msg = geterr(rc)->msg_detail;
    return OK_SUCCEEDED;
}

/**
 * Get the error definition according to the status code.
 * @param rc status code.
 * @param def Where to store the pointer of text.
 * @return OK_SUCCEEDED.
 * @return else if failed.
 */
DECL(int) uv_error_def(int rc, const char **def) {
    CHECK_STRICT_PTR(def);
    
    *def = geterr(rc)->definition;
    return OK_SUCCEEDED;
}

/**
 * Register a event callback.
 * @param p Pointer to the viewer context.
 * @param t Type of target event.
 * @param pf Pointer to the service function.
 * @return status code
 */
DECL(int) uv_register_event(uview_t *p, event_type_t t, void *pf) {
    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(pf);
    CHECK_MAGIC(p->magic);

    switch (t) {
        case EVENT_SHOW_INPUTBOX:
            p->cb_event_inputbox = (fnEventInputBox)pf;
            break;
        case EVENT_SHOW_CHECKBOX:
            p->cb_event_checkbox = (fnEventCheckBox)pf;
            break;
        case EVENT_REPAINT_VIEW:
            p->cb_event_repaint_view = (fnEventRepaintView)pf;
            break;
        case EVENT_GOTO_PAGE:
            p->cb_event_goto_page = (fnEventGotoPage)pf;
            break;
        case EVENT_GOTO_URL:
            p->cb_event_goto_url = (fnEventGotoURL)pf;
            break;
        case EVENT_CURSOR:
            p->cb_event_cursor = (fnEventCursor)pf;
            break;
        case EVENT_WARN:
            p->cb_event_warn = (fnEventWarn)pf;
            break;
        default:
            return ERR_INVALID_PARAMETER;
    }

    return OK_SUCCEEDED;
}

/**
 * Handle mouse event. Through this function we can have
 * interactive between GUI and viewer back-end.
 * @return status code
 */
DECL(int) uv_mouse_event(uview_t *p, pixmap_t *pix, int x, int y, int btn, int modifiers, int state) {
    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(pix);
    CHECK_MAGIC(p->magic);

    /* validate the context */
    if (pix->magic != PIXMAP_MAGIC)
        return ERR_INVALID_MAGIC;
    if (!p->doc)
        return ERR_NOT_OPENED;
    if (!pix->page)
        return ERR_NO_ENOUGH_INFOMATION;

    fz_irect irect;
    fz_link *link;
    fz_matrix ctm;
    fz_point point;
    int processed = 0;

    fz_pixmap_bbox(p->uv, pix->p, &irect);
    point.x = x /* - panx*/ + irect.x0;
    point.y = y /* - pany*/ + irect.y0;

    ctm = p->ctm;
    fz_invert_matrix(&ctm, &ctm);
    fz_transform_point(&point, &ctm);

    /*
     * Process the Widget if needed
     */
    if (btn == 1 && (state == 1 || state == -1)) {
        pdf_ui_event event;
        pdf_document *idoc = pdf_specifics(p->uv, p->doc);

        event.etype = PDF_EVENT_TYPE_POINTER;
        event.event.pointer.pt = point;
        if (state == 1)
            event.event.pointer.ptype = PDF_POINTER_DOWN;
        else /* state == -1 */
            event.event.pointer.ptype = PDF_POINTER_UP;

        if (idoc && pdf_pass_event(p->uv, idoc, (pdf_page *)pix->page, &event)) {
            pdf_widget *widget;

            widget = pdf_focused_widget(p->uv, idoc);

            POST_EVENT(p, cursor, (p, WAIT));
            POST_EVENT(p, repaint_view, (p));

            if (widget) {
                switch (pdf_widget_get_type(p->uv, widget)) {
                case PDF_WIDGET_TYPE_TEXT: {
                 if (p->cb_event_inputbox != dummy_p_cs_n_rc) {
                    char *text = pdf_text_widget_text(p->uv, idoc, widget);
                    char *current_text = text;
                    int retry = 0;

                    do {
                        current_text = POST_EVENT(p, inputbox, (p, current_text, retry));
                        retry = 1;
                    }
                    while (current_text && !pdf_text_widget_set_text(p->uv, idoc, widget, current_text));

                    fz_free(p->uv, text);
                    POST_EVENT(p, repaint_view, (p));
                 }
                }
                break;

                case PDF_WIDGET_TYPE_LISTBOX:
                case PDF_WIDGET_TYPE_COMBOBOX: {
                    int nopts;
                    int nvals;
                    char **opts = NULL;
                    char **vals = NULL;

                    fz_var(opts);
                    fz_var(vals);

                    fz_try(p->uv) {
                        nopts = pdf_choice_widget_options(p->uv, idoc, widget, 0, NULL);
                        opts = fz_malloc(p->uv, nopts * sizeof(*opts));
                        (void)pdf_choice_widget_options(p->uv, idoc, widget, 0, opts);

                        nvals = pdf_choice_widget_value(p->uv, idoc, widget, NULL);
                        vals = fz_malloc(p->uv, MAX(nvals,nopts) * sizeof(*vals));
                        (void)pdf_choice_widget_value(p->uv, idoc, widget, vals);

                        if (POST_EVENT(p, checkbox, (p, nopts, opts, &nvals, vals))) {
                            pdf_choice_widget_set_value(p->uv, idoc, widget, nvals, vals);
                            POST_EVENT(p, repaint_view, (p));
                        }
                    }
                    fz_always(p->uv) {
                        fz_free(p->uv, opts);
                        fz_free(p->uv, vals);
                    }
                    fz_catch(p->uv) {
                        POST_EVENT(p, warn, (p, "setting of choice failed"));
                    }
                }
                break;

                case PDF_WIDGET_TYPE_SIGNATURE: {
                    char ebuf[256];

                    ebuf[0] = 0;
                    if (pdf_check_signature(p->uv, idoc, widget, p->docpath, ebuf, sizeof(ebuf))) {
                        POST_EVENT(p, warn, (p, "Signature is valid"));
                    } else {
                        if (ebuf[0] == 0)
                            POST_EVENT(p, warn, (p, "Signature check failed for unknown reason"));
                        else
                            POST_EVENT(p, warn, (p, ebuf));
                    }
                }
                break;
                } // switch
            } // if (widget)

            POST_EVENT(p, cursor, (p, NORMAL));
            processed = 1;
        }
    }

    /*
     * Find the links
     */
    for (link = pix->page_links; link; link = link->next) {
        if (point.x >= link->rect.x0 && point.x <= link->rect.x1)
            if (point.y >= link->rect.y0 && point.y <= link->rect.y1)
                break;
    }

    /*
     * Process the Links if needed
     */
    if (link) {
        p->cb_event_cursor(p, HAND);
        if (btn == 1 && state == 1 && !processed) {
            if (link->dest.kind == FZ_LINK_URI)
                POST_EVENT(p, goto_url, (p, link->dest.ld.uri.uri));
            else if (link->dest.kind == FZ_LINK_GOTO)
                POST_EVENT(p, goto_page, (p, link->dest.ld.gotor.page + 1));
            return OK_SUCCEEDED;
        }
    } else {
        fz_annot *annot;
        for (annot = fz_first_annot(p->uv, pix->page); annot; annot = fz_next_annot(p->uv, annot)) {
            fz_rect rect;
            fz_bound_annot(p->uv, annot, &rect);
            if (x >= rect.x0 && x < rect.x1)
                if (y >= rect.y0 && y < rect.y1)
                    break;
        }
        if (annot)
            POST_EVENT(p, cursor, (p, CARET));
        else
            POST_EVENT(p, cursor, (p, ARROW));
    }
    
    return OK_SUCCEEDED;
}


/**
 * Load a doucment file.
 * @param p Pointer to the viewer context.
 * @param fn Filename.
 * @param flags Extra flags.
 * @return status code.
 */
DECL(int) uv_open_file(uview_t *p, const char *fn, int flags) {
    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(fn);
    if (p->magic != UVIEW_MAGIC)
        return ERR_INVALID_MAGIC;
    
    /* Open the document */
    fz_try(p->uv)
		p->doc = fz_open_document(p->uv, fn);
	fz_catch(p->uv) {
	    p->doc = NULL;
		MSG("cannot open document: %s\n", fz_caught_message(p->uv));
		return ERR_FAILED;
	}
    
    /* Count the number of pages */
    fz_try(p->uv)
		p->page_count = fz_count_pages(p->uv, p->doc);
	fz_catch(p->uv) {
	    p->page_count = 0;
		MSG("cannot count number of pages: %s\n", fz_caught_message(p->uv));
		fz_drop_document(p->uv, p->doc);
		p->doc = NULL;
		return ERR_COUNT_PAGES;
	}

#if 0
	/* get the outline information */
	while (1) {
        fz_try(p->uv) {
            p->outline = fz_load_outline(p->uv, p->doc);
        }
        fz_catch(p->uv) {
            if (fz_caught(p->uv) == FZ_ERROR_TRYLATER) {
                p->outline_deferred = PDFAPP_OUTLINE_DEFERRED;
            }
            else {
                fz_drop_document(p->uv, p->doc);
                p->doc = NULL;
                return ERR_GET_OUTLINE;
            }
        }
        break;
    }
#else
	p->outline = NULL;
#endif

    /* fill the basic information of document */
    p->docpath = fz_strdup(p->uv, fn);
	if (!p->docpath) {
	    fz_drop_document(p->uv, p->doc);
        p->doc = NULL;
        return ERR_ALLOC_MEMORY;
	}

	/* Compute a transformation matrix for the zoom and rotation desired. */
    /* The default resolution without scaling is 72 dpi. */
    fz_scale(&p->ctm, 1.0, 1.0);
    fz_pre_rotate(&p->ctm, 0.0);
    
    return OK_SUCCEEDED;
}

/**
 * Render the page to an RGB pixmap.
 * NOTE: this function will create a new pixmap area to store
 * the informations, and we should release it by calling
 * uv_pixmap_drop().
 * @param p Pointer to the context.
 * @param page The index of current page.
 * @param pix Where to store the pointer of pixmap area.
 * @return status code.
 */
DECL(int) uv_render_pixmap(uview_t *p, int page, pixmap_t **pix) {
    fz_pixmap *fpix;

    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(pix);

    if (p->magic != UVIEW_MAGIC)
        return ERR_INVALID_MAGIC;
    if (!p->doc)
        return ERR_NOT_OPENED;
    if (page <= 0 || page > p->page_count)
        return ERR_INVALID_PAGE;

    /*
     * Render page to an RGB pixmap.
     */
    fz_try(p->uv)
        fpix = fz_new_pixmap_from_page_number(p->uv, p->doc, page - 1, &p->ctm, p->colorspace);
    fz_catch(p->uv) {
        MSG("cannot render page: %s\n", fz_caught_message(p->uv));
        return ERR_FAILED;
    }

    /*
     * Create a pixmap object
     */
    pixmap_t *pixmap = (pixmap_t *)malloc(sizeof(*pixmap));
    if (!pixmap) {
        fz_drop_pixmap(p->uv, fpix);
        return ERR_ALLOC_MEMORY;
    }

    pixmap->magic = PIXMAP_MAGIC;
    pixmap->w = fpix->w;
    pixmap->h = fpix->h;
    pixmap->n = fpix->n;
    pixmap->samples = (char*)fpix->samples;
    pixmap->p = fpix;
    pixmap->page = NULL;
    pixmap->page_links = NULL;
    pixmap->pageno = page;
    pixmap->incomplete = 0;
    pixmap->resolution = 72;
    *pix = pixmap;
    return OK_SUCCEEDED;
}

/**
 * Fill the page information to pixmap object
 * @param p Pointer to the context.
 * @param pix Pointer to the target pixmap
 * @return status code.
 */
DECL(int) uv_pixmap_fill_docinfo(uview_t *p, pixmap_t *pix) {
    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(pix);
    CHECK_MAGIC(p->magic);

    if (pix->magic != PIXMAP_MAGIC)
        return ERR_INVALID_MAGIC;
    if (!p->doc)
        return ERR_NOT_OPENED;

    /* ensure that we have released all the memory object */
    if (pix->page_links)
        fz_drop_link(p->uv, pix->page_links);
    if (pix->page)
        fz_drop_page(p->uv, pix->page);

    pix->page_links = NULL;
    pix->page = NULL;
    pix->page_bbox.x0 = 0;
    pix->page_bbox.y0 = 0;
    pix->page_bbox.x1 = 100;
    pix->page_bbox.y1 = 100;

    /* Load the infomation of page */
    fz_try(p->uv) {
        pix->page = fz_load_page(p->uv, p->doc, pix->pageno - 1);
        fz_bound_page(p->uv, pix->page, &pix->page_bbox);
    }
    fz_catch(p->uv) {
        if (fz_caught(p->uv) == FZ_ERROR_TRYLATER)
            pix->incomplete = 1;
        pix->page = NULL;
        return ERR_FAILED;
    }

    /* Resolve all the links */
    fz_try(p->uv) {
        pix->page_links = fz_load_links(p->uv, pix->page);
    }
    fz_catch(p->uv) {
        if (fz_caught(p->uv) == FZ_ERROR_TRYLATER)
            pix->incomplete = 1;
        else {
            pix->page_links = NULL;
            return ERR_RESOLVE_LINKS;
        }
    }

    return OK_SUCCEEDED;
}

/**
 * Get the informations of pixmap object.
 * @param p Pointer to the context.
 * @param pix Pointer to the target pixmap.
 * @param w Where to store the width.
 * @param h Where to store the height.
 * @param n Where to store the length of samples.
 * @param samples Where to store the pointer of samples.
 */
DECL(int) uv_pixmap_getinfos(uview_t *p, pixmap_t *pix, int *w, int *h, int *n, char **samples) {
    CHECK_STRICT_PTR(p);
    CHECK_STRICT_PTR(pix);
    CHECK_STRICT_PTR(w);
    CHECK_STRICT_PTR(h);
    CHECK_STRICT_PTR(n);
    CHECK_STRICT_PTR(samples);
    CHECK_MAGIC(p->magic);

    if (pix->magic != PIXMAP_MAGIC)
        return ERR_INVALID_MAGIC;

    *w = pix->w;
    *h = pix->h;
    *n = pix->n;
    *samples = pix->samples;
    return OK_SUCCEEDED;
}

/**
 * Destroy the pixmap object
 * @param p Pointer to the context.
 * @param pix Pointer to the target pixmap object.
 */
DECL(void) uv_drop_pixmap(uview_t *p, pixmap_t *pix) {
    CHECKR_STRICT_PTR(p);
    CHECKR_STRICT_PTR(pix);
    CHECKR_MAGIC(p->magic);

    if (pix->magic != PIXMAP_MAGIC)
        return;

    if (pix->p)
        fz_drop_pixmap(p->uv, pix->p);

    pix->magic = 0xbadbeef; // invalid magic
    free(pix);
}
