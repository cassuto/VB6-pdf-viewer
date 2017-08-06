#ifndef UVIEW_FITZ_OUTPUT_SVG_H
#define UVIEW_FITZ_OUTPUT_SVG_H

#include "uview/fitz/system.h"
#include "uview/fitz/context.h"
#include "uview/fitz/device.h"
#include "uview/fitz/output.h"

fz_device *fz_new_svg_device(fz_context *ctx, fz_output *out, float page_width, float page_height);

#endif
