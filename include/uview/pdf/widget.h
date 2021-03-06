#ifndef UVIEW_PDF_WIDGET_H
#define UVIEW_PDF_WIDGET_H

/* Types of widget */
enum
{
	PDF_WIDGET_TYPE_NOT_WIDGET = -1,
	PDF_WIDGET_TYPE_PUSHBUTTON,
	PDF_WIDGET_TYPE_CHECKBOX,
	PDF_WIDGET_TYPE_RADIOBUTTON,
	PDF_WIDGET_TYPE_TEXT,
	PDF_WIDGET_TYPE_LISTBOX,
	PDF_WIDGET_TYPE_COMBOBOX,
	PDF_WIDGET_TYPE_SIGNATURE
};

/* Types of text widget content */
enum
{
	PDF_WIDGET_CONTENT_UNRESTRAINED,
	PDF_WIDGET_CONTENT_NUMBER,
	PDF_WIDGET_CONTENT_SPECIAL,
	PDF_WIDGET_CONTENT_DATE,
	PDF_WIDGET_CONTENT_TIME
};

/*
	Widgets that may appear in PDF forms
*/

/*
	pdf_focused_widget: returns the currently focussed widget

	Widgets can become focussed as a result of passing in ui events.
	NULL is returned if there is no currently focussed widget. An
	app may wish to create a native representative of the focussed
	widget, e.g., to collect the text for a text widget, rather than
	routing key strokes through pdf_pass_event.
*/
pdf_widget *pdf_focused_widget(fz_context *ctx, pdf_document *doc);

/*
	pdf_first_widget: get first widget when enumerating
*/
pdf_widget *pdf_first_widget(fz_context *ctx, pdf_document *doc, pdf_page *page);

/*
	pdf_next_widget: get next widget when enumerating
*/
pdf_widget *pdf_next_widget(fz_context *ctx, pdf_widget *previous);

/*
	pdf_create_widget: create a new widget of a specific type
*/
pdf_widget *pdf_create_widget(fz_context *ctx, pdf_document *doc, pdf_page *page, int type, char *fieldname);

/*
	pdf_widget_get_type: find out the type of a widget.

	The type determines what widget subclass the widget
	can safely be cast to.
*/
int pdf_widget_get_type(fz_context *ctx, pdf_widget *widget);

/*
	pdf_bound_widget: get the bounding box of a widget.
*/
fz_rect *pdf_bound_widget(fz_context *ctx, pdf_widget *widget, fz_rect *);

/*
	pdf_text_widget_text: Get the text currently displayed in
	a text widget.
*/
char *pdf_text_widget_text(fz_context *ctx, pdf_document *doc, pdf_widget *tw);

/*
	pdf_widget_text_max_len: get the maximum number of
	characters permitted in a text widget
*/
int pdf_text_widget_max_len(fz_context *ctx, pdf_document *doc, pdf_widget *tw);

/*
	pdf_text_widget_content_type: get the type of content
	required by a text widget
*/
int pdf_text_widget_content_type(fz_context *ctx, pdf_document *doc, pdf_widget *tw);

/*
	pdf_text_widget_set_text: Update the text of a text widget.
	The text is first validated and accepted only if it passes. The
	function returns whether validation passed.
*/
int pdf_text_widget_set_text(fz_context *ctx, pdf_document *doc, pdf_widget *tw, char *text);

/*
	pdf_choice_widget_options: get the list of options for a list
	box or combo box. Returns the number of options and fills in their
	names within the supplied array. Should first be called with a
	NULL array to find out how big the array should be.  If exportval
	is true, then the export values will be returned and not the list
	values if there are export values present.
*/
int pdf_choice_widget_options(fz_context *ctx, pdf_document *doc, pdf_widget *tw, int exportval, char *opts[]);

/*
	pdf_choice_widget_is_multiselect: returns whether a list box or
	combo box supports selection of multiple options
*/
int pdf_choice_widget_is_multiselect(fz_context *ctx, pdf_document *doc, pdf_widget *tw);

/*
	pdf_choice_widget_value: get the value of a choice widget.
	Returns the number of options curently selected and fills in
	the supplied array with their strings. Should first be called
	with NULL as the array to find out how big the array need to
	be. The filled in elements should not be freed by the caller.
*/
int pdf_choice_widget_value(fz_context *ctx, pdf_document *doc, pdf_widget *tw, char *opts[]);

/*
	pdf_widget_set_value: set the value of a choice widget. The
	caller should pass the number of options selected and an
	array of their names
*/
void pdf_choice_widget_set_value(fz_context *ctx, pdf_document *doc, pdf_widget *tw, int n, char *opts[]);

#endif
