#ifndef UVIEW_FITZ_OUTPUT_PS_H
#define UVIEW_FITZ_OUTPUT_PS_H

#include "uview/fitz/system.h"
#include "uview/fitz/context.h"
#include "uview/fitz/output.h"
#include "uview/fitz/pixmap.h"

typedef struct fz_ps_output_context_s fz_ps_output_context;

/*
	PS (image) output
*/
void fz_write_pixmap_as_ps(fz_context *ctx, fz_output *out, const fz_pixmap *pixmap);

void fz_save_pixmap_as_ps(fz_context *ctx, fz_pixmap *pixmap, char *filename, int append);

void fz_write_ps_file_header(fz_context *ctx, fz_output *out);

fz_ps_output_context *fz_write_ps_header(fz_context *ctx, fz_output *out, int w, int h, int n, int xres, int yres, int pagenum);

void fz_write_ps_band(fz_context *ctx, fz_output *out, fz_ps_output_context *psoc, int w, int h, int n, int band, int bandheight, unsigned char *samples);

void fz_write_ps_trailer(fz_context *ctx, fz_output *out, fz_ps_output_context *psoc);

void fz_write_ps_file_trailer(fz_context *ctx, fz_output *out, int pages);

#endif
