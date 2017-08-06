#ifndef UVIEW_FITZ_OUTPUT_TGA_H
#define UVIEW_FITZ_OUTPUT_TGA_H

#include "uview/fitz/system.h"
#include "uview/fitz/context.h"
#include "uview/fitz/pixmap.h"

void fz_save_pixmap_as_tga(fz_context *ctx, fz_pixmap *pixmap, const char *filename, int savealpha);
void fz_write_pixmap_as_tga(fz_context *ctx, fz_output *out, fz_pixmap *pixmap, int savealpha);

#endif
