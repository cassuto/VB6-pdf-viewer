#ifndef UVIEW_PDF_FIELD_H
#define UVIEW_PDF_FIELD_H

/* Field flags */
enum
{
	/* Common to all field types */
	Ff_ReadOnly = 1 << (1-1),
	Ff_Required = 1 << (2-1),
	Ff_NoExport = 1 << (3-1),

	/* Text fields */
	Ff_Multiline = 1 << (13-1),
	Ff_Password = 1 << (14-1),

	Ff_FileSelect = 1 << (21-1),
	Ff_DoNotSpellCheck = 1 << (23-1),
	Ff_DoNotScroll = 1 << (24-1),
	Ff_Comb = 1 << (25-1),
	Ff_RichText = 1 << (26-1),

	/* Button fields */
	Ff_NoToggleToOff = 1 << (15-1),
	Ff_Radio = 1 << (16-1),
	Ff_Pushbutton = 1 << (17-1),
	Ff_RadioInUnison = 1 << (26-1),

	/* Choice fields */
	Ff_Combo = 1 << (18-1),
	Ff_Edit = 1 << (19-1),
	Ff_Sort = 1 << (20-1),
	Ff_MultiSelect = 1 << (22-1),
	Ff_CommitOnSelCHange = 1 << (27-1),
};

char *pdf_get_string_or_stream(fz_context *ctx, pdf_document *doc, pdf_obj *obj);
pdf_obj *pdf_get_inheritable(fz_context *ctx, pdf_document *doc, pdf_obj *obj, pdf_obj *key);
int pdf_get_field_flags(fz_context *ctx, pdf_document *doc, pdf_obj *obj);
int pdf_field_type(fz_context *ctx, pdf_document *doc, pdf_obj *field);
void pdf_set_field_type(fz_context *ctx, pdf_document *doc, pdf_obj *obj, int type);
char *pdf_field_value(fz_context *ctx, pdf_document *doc, pdf_obj *field);
int pdf_field_set_value(fz_context *ctx, pdf_document *doc, pdf_obj *field, const char *text);
char *pdf_field_border_style(fz_context *ctx, pdf_document *doc, pdf_obj *field);
void pdf_field_set_border_style(fz_context *ctx, pdf_document *doc, pdf_obj *field, const char *text);
void pdf_field_set_button_caption(fz_context *ctx, pdf_document *doc, pdf_obj *field, const char *text);
void pdf_field_set_fill_color(fz_context *ctx, pdf_document *doc, pdf_obj *field, pdf_obj *col);
void pdf_field_set_text_color(fz_context *ctx, pdf_document *doc, pdf_obj *field, pdf_obj *col);
void pdf_signature_set_value(fz_context *ctx, pdf_document *doc, pdf_obj *field, pdf_signer *signer);
int pdf_field_display(fz_context *ctx, pdf_document *doc, pdf_obj *field);
char *pdf_field_name(fz_context *ctx, pdf_document *doc, pdf_obj *field);
void pdf_field_set_display(fz_context *ctx, pdf_document *doc, pdf_obj *field, int d);
pdf_obj *pdf_lookup_field(fz_context *ctx, pdf_obj *form, char *name);
void pdf_field_reset(fz_context *ctx, pdf_document *doc, pdf_obj *field);

#endif
