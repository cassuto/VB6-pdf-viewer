# GNU Makefile

build ?= release

OUT := build/$(build)
GEN := generated

default: all

# --- Configuration ---

include rules.mk
include libs.mk

# Do not specify CFLAGS or LIBS on the make invocation line - specify
# XCFLAGS or XLIBS instead. Make ignores any lines in the makefile that
# set a variable that was set on the command line.
CFLAGS += $(XCFLAGS) -Iinclude -I$(GEN)
LIBS += $(XLIBS) -lm

LIBS += $(FREETYPE_LIBS)
LIBS += $(HARFBUZZ_LIBS)
LIBS += $(JBIG2DEC_LIBS)
LIBS += $(JPEG_LIBS)
LIBS += $(MUJS_LIBS)
LIBS += $(OPENJPEG_LIBS)
LIBS += $(OPENSSL_LIBS)
LIBS += $(ZLIB_LIBS)

CFLAGS += $(FREETYPE_CFLAGS)
CFLAGS += $(HARFBUZZ_CFLAGS)
CFLAGS += $(JBIG2DEC_CFLAGS)
CFLAGS += $(JPEG_CFLAGS)
CFLAGS += $(MUJS_CFLAGS)
CFLAGS += $(OPENJPEG_CFLAGS)
CFLAGS += $(OPENSSL_CFLAGS)
CFLAGS += $(ZLIB_CFLAGS)

$(info configure dump:)
$(info OS = $(strip $(OS)))
$(info LIBS = $(strip $(LIBS)))
$(info CFLAGS = $(strip $(CFLAGS)))
$(info )
$(info =================================)
$(info Scaning the dependency...)
$(info =================================)


# --- Commands ---

ifneq "$(verbose)" "yes"
QUIET_AR = @ echo ' ' ' ' AR $@ ;
QUIET_CC = @ echo ' ' ' ' CC $@ ;
QUIET_CXX = @ echo ' ' ' ' CXX $@ ;
QUIET_GEN = @ echo ' ' ' ' GEN $@ ;
QUIET_LINK = @ echo ' ' ' ' LINK $@ ;
QUIET_MKDIR = @ echo ' ' ' ' MKDIR $@ ;
QUIET_RM = @ echo ' ' ' ' RM $@ ;
endif

CC_CMD = $(QUIET_CC) $(CC) $(CFLAGS) -o $@ -c $<
CXX_CMD = $(QUIET_CXX) $(CXX) $(CFLAGS) -o $@ -c $<
AR_CMD = $(QUIET_AR) $(AR) cr $@ $^
LINK_CMD = $(QUIET_LINK) $(CC) $(LDFLAGS) -o $@ $^ $(LIBS)
MKDIR_CMD = $(QUIET_MKDIR) mkdir -p $@
RM_CMD = $(QUIET_RM) rm -f $@

# --- File lists ---

ALL_DIR := $(OUT)/fitz
ALL_DIR += $(OUT)/pdf $(OUT)/pdf/js
ALL_DIR += $(OUT)/xps
ALL_DIR += $(OUT)/cbz
ALL_DIR += $(OUT)/img
ALL_DIR += $(OUT)/tiff
ALL_DIR += $(OUT)/html
ALL_DIR += $(OUT)/gprf
ALL_DIR += $(OUT)/tools
ALL_DIR += $(OUT)/builtin
ALL_DIR += $(OUT)/platform/x11
ALL_DIR += $(OUT)/platform/x11/curl
ALL_DIR += $(OUT)/platform/vb6
ALL_DIR += $(OUT)/platform/gl
ALL_DIR += $(OUT)/fonts

FITZ_HDR := include/uview/fitz.h $(wildcard include/uview/fitz/*.h)
PDF_HDR := include/uview/pdf.h $(wildcard include/uview/pdf/*.h)
XPS_HDR := include/uview/xps.h
HTML_HDR := include/uview/html.h

FITZ_SRC := $(wildcard src/fitz/*.c)
PDF_SRC := $(wildcard src/pdf/*.c)
XPS_SRC := $(wildcard src/xps/*.c)
CBZ_SRC := $(wildcard src/cbz/*.c)
HTML_SRC := $(wildcard src/html/*.c)
GPRF_SRC := $(wildcard src/gprf/*.c)

FITZ_SRC_HDR := $(wildcard src/fitz/*.h)
PDF_SRC_HDR := $(wildcard src/pdf/*.h) src/pdf/pdf-name-table.h
XPS_SRC_HDR := $(wildcard src/xps/*.h)
HTML_SRC_HDR := $(wildcard src/html/*.h)
GPRF_SRC_HDR := $(wildcard src/gprf/*.h)

FITZ_OBJ := $(subst src/, $(OUT)/, $(addsuffix .o, $(basename $(FITZ_SRC))))
PDF_OBJ := $(subst src/, $(OUT)/, $(addsuffix .o, $(basename $(PDF_SRC))))
XPS_OBJ := $(subst src/, $(OUT)/, $(addsuffix .o, $(basename $(XPS_SRC))))
CBZ_OBJ := $(subst src/, $(OUT)/, $(addsuffix .o, $(basename $(CBZ_SRC))))
HTML_OBJ := $(subst src/, $(OUT)/, $(addsuffix .o, $(basename $(HTML_SRC))))
GPRF_OBJ := $(subst src/, $(OUT)/, $(addsuffix .o, $(basename $(GPRF_SRC))))

ifeq "$(HAVE_MUJS)" "yes"
PDF_OBJ += $(OUT)/pdf/js/pdf-js.o
else
PDF_OBJ += $(OUT)/pdf/js/pdf-js-none.o
endif

$(FITZ_OBJ) : $(FITZ_HDR) $(FITZ_SRC_HDR)
$(PDF_OBJ) : $(FITZ_HDR) $(PDF_HDR) $(PDF_SRC_HDR)
$(XPS_OBJ) : $(FITZ_HDR) $(XPS_HDR) $(XPS_SRC_HDR)
$(CBZ_OBJ) : $(FITZ_HDR)
$(HTML_OBJ) : $(FITZ_HDR) $(HTML_HDR) $(HTML_SRC_HDR)
$(GPRF_OBJ) : $(FITZ_HDR) $(GPRF_HDR) $(GPRF_SRC_HDR)

# --- Generated embedded font files ---

FONT_BIN_DROID := $(wildcard resources/fonts/droid/*.ttc)
FONT_BIN_NOTO := $(wildcard resources/fonts/noto/*.ttf)
FONT_BIN_URW := $(wildcard resources/fonts/urw/*.cff)
FONT_BIN_SIL := $(wildcard resources/fonts/sil/*.cff)

FONT_GEN_DROID := $(subst resources/fonts/droid/, $(GEN)/, $(addsuffix .c, $(basename $(FONT_BIN_DROID))))
FONT_GEN_NOTO := $(subst resources/fonts/noto/, $(GEN)/, $(addsuffix .c, $(basename $(FONT_BIN_NOTO))))
FONT_GEN_URW := $(subst resources/fonts/urw/, $(GEN)/, $(addsuffix .c, $(basename $(FONT_BIN_URW))))
FONT_GEN_SIL := $(subst resources/fonts/sil/, $(GEN)/, $(addsuffix .c, $(basename $(FONT_BIN_SIL))))

FONT_BIN := $(FONT_BIN_DROID) $(FONT_BIN_NOTO) $(FONT_BIN_URW) $(FONT_BIN_SIL)
FONT_GEN := $(FONT_GEN_DROID) $(FONT_GEN_NOTO) $(FONT_GEN_URW) $(FONT_GEN_SIL)
FONT_OBJ := $(subst $(GEN)/, $(OUT)/fonts/, $(addsuffix .o, $(basename $(FONT_GEN))))
FONT_TINY_OBJ := $(subst $(GEN)/, $(OUT)/fonts/, $(addsuffix .o, $(basename $(FONT_GEN_URW))))

$(GEN)/%.c : resources/fonts/droid/%.ttc $(FONTDUMP)
	$(QUIET_GEN) $(FONTDUMP) $@ $<
$(GEN)/%.c : resources/fonts/noto/%.ttf $(FONTDUMP)
	$(QUIET_GEN) $(FONTDUMP) $@ $<
$(GEN)/%.c : resources/fonts/urw/%.cff $(FONTDUMP)
	$(QUIET_GEN) $(FONTDUMP) $@ $<
$(GEN)/%.c : resources/fonts/sil/%.cff $(FONTDUMP)
	$(QUIET_GEN) $(FONTDUMP) $@ $<

$(FONT_OBJ) : $(FONT_GEN)
$(FONT_GEN_DROID) : $(FONT_BIN_DROID)
$(FONT_GEN_NOTO) : $(FONT_BIN_NOTO)
$(FONT_GEN_URW) : $(FONT_BIN_URW)

ifeq "$(OS)" "MINGW"
  SHARED_OBJ_EXT = dll
else
  SHARED_OBJ_EXT = so
endif

# --- Library ---

UVIEW_LIB = $(OUT)/libuviewer.a
THIRD_LIB = $(OUT)/libuvexts.a
FONTS_LIB = $(OUT)/libuvfonts.$(SHARED_OBJ_EXT)
FONTS_TINY_LIB = $(OUT)/libuvfonts-tiny.$(SHARED_OBJ_EXT)

UVIEW_OBJ := $(FITZ_OBJ) $(PDF_OBJ) $(XPS_OBJ) $(CBZ_OBJ) $(HTML_OBJ) $(GPRF_OBJ)
THIRD_OBJ := $(FREETYPE_OBJ) $(HARFBUZZ_OBJ) $(JBIG2DEC_OBJ) $(JPEG_OBJ) $(MUJS_OBJ) $(OPENJPEG_OBJ) $(ZLIB_OBJ)

$(UVIEW_LIB) : $(UVIEW_OBJ)
$(THIRD_LIB) : $(THIRD_OBJ)
$(FONTS_LIB) : $(FONT_OBJ) $(OUT)/builtin/builtin-font.o
$(FONTS_TINY_LIB) : $(FONT_TINY_OBJ) $(OUT)/builtin/builtin-font-tiny.o

INSTALL_LIBS := $(UVIEW_LIB) $(THIRD_LIB) $(FONTS_LIB) $(FONTS_TINY_LIB)

# --- Rules ---

$(ALL_DIR) $(OUT) $(GEN) :
	$(MKDIR_CMD)

$(OUT)/%.a :
	$(RM_CMD)
	$(AR_CMD)
	$(RANLIB_CMD)

$(OUT)/%.dll :
	$(LINK_CMD) -shared -Wl,--out-implib,$(basename $@).a

$(OUT)/%.so :
	$(LINK_CMD) -shared
    
$(OUT)/%: $(OUT)/%.o
	$(LINK_CMD)

$(OUT)/%.o : src/%.c | $(ALL_DIR)
	$(CC_CMD)

$(OUT)/%.o : src/%.cpp | $(ALL_DIR)
	$(CXX_CMD)

$(OUT)/%.o : scripts/%.c | $(OUT)
	$(CC_CMD)

$(OUT)/fonts/%.o : $(GEN)/%.c | $(ALL_DIR)
	$(CC_CMD) -O0

$(OUT)/platform/x11/%.o : platform/x11/%.c | $(ALL_DIR)
	$(CC_CMD) $(X11_CFLAGS)

$(OUT)/platform/x11/curl/%.o : platform/x11/%.c | $(ALL_DIR)
	$(CC_CMD) $(X11_CFLAGS) $(CURL_CFLAGS) -DHAVE_CURL

$(OUT)/platform/vb6/%.o : platform/vb6/%.c | $(ALL_DIR)
	$(CC_CMD) $(VB6_CFLAGS)
    
$(OUT)/platform/gl/%.o : platform/gl/%.c | $(ALL_DIR)
	$(CC_CMD) $(GLFW_CFLAGS)

.PRECIOUS : $(OUT)/%.o # Keep intermediates from chained rules

# --- Generated CMap and JavaScript files ---

CMAPDUMP := $(OUT)/cmapdump
FONTDUMP := $(OUT)/fontdump
NAMEDUMP := $(OUT)/namedump
CQUOTE := $(OUT)/cquote
BIN2HEX := $(OUT)/bin2hex

CMAP_CNS_SRC := $(wildcard resources/cmaps/cns/*)
CMAP_GB_SRC := $(wildcard resources/cmaps/gb/*)
CMAP_JAPAN_SRC := $(wildcard resources/cmaps/japan/*)
CMAP_KOREA_SRC := $(wildcard resources/cmaps/korea/*)

$(GEN)/gen_cmap_cns.h : $(CMAP_CNS_SRC)
	$(QUIET_GEN) $(CMAPDUMP) $@ $(CMAP_CNS_SRC)
$(GEN)/gen_cmap_gb.h : $(CMAP_GB_SRC)
	$(QUIET_GEN) $(CMAPDUMP) $@ $(CMAP_GB_SRC)
$(GEN)/gen_cmap_japan.h : $(CMAP_JAPAN_SRC)
	$(QUIET_GEN) $(CMAPDUMP) $@ $(CMAP_JAPAN_SRC)
$(GEN)/gen_cmap_korea.h : $(CMAP_KOREA_SRC)
	$(QUIET_GEN) $(CMAPDUMP) $@ $(CMAP_KOREA_SRC)

CMAP_GEN := $(addprefix $(GEN)/, gen_cmap_cns.h gen_cmap_gb.h gen_cmap_japan.h gen_cmap_korea.h)

include/uview/pdf.h : include/uview/pdf/name-table.h
NAME_GEN := include/uview/pdf/name-table.h src/pdf/pdf-name-table.h
$(NAME_GEN) : resources/pdf/names.txt
	$(QUIET_GEN) $(NAMEDUMP) resources/pdf/names.txt $(NAME_GEN)

JAVASCRIPT_SRC := src/pdf/js/pdf-util.js
JAVASCRIPT_GEN := $(GEN)/gen_js_util.h
$(JAVASCRIPT_GEN) : $(JAVASCRIPT_SRC)
	$(QUIET_GEN) $(CQUOTE) $@ $(JAVASCRIPT_SRC)

ADOBECA_SRC := resources/certs/AdobeCA.p7c
ADOBECA_GEN := $(GEN)/gen_adobe_ca.h
$(ADOBECA_GEN) : $(ADOBECA_SRC)
	$(QUIET_GEN) $(BIN2HEX) $@ $(ADOBECA_SRC)

ifneq "$(CROSSCOMPILE)" "yes"
$(CMAP_GEN) : $(CMAPDUMP) | $(GEN)
$(FONT_GEN) : $(FONTDUMP) | $(GEN)
$(NAME_GEN) : $(NAMEDUMP) | $(GEN)
$(JAVASCRIPT_GEN) : $(CQUOTE) | $(GEN)
$(ADOBECA_GEN) : $(BIN2HEX) | $(GEN)
endif

generate: $(CMAP_GEN) $(FONT_GEN) $(JAVASCRIPT_GEN) $(ADOBECA_GEN) $(NAME_GEN)

$(OUT)/pdf/pdf-cmap-table.o : $(CMAP_GEN)
$(OUT)/pdf/pdf-pkcs7.o : $(ADOBECA_GEN)
$(OUT)/pdf/js/pdf-js.o : $(JAVASCRIPT_GEN)
$(OUT)/pdf/pdf-object.o : src/pdf/pdf-name-table.h
$(OUT)/cmapdump.o : include/uview/pdf/cmap.h src/pdf/pdf-cmap.c src/pdf/pdf-cmap-parse.c src/pdf/pdf-name-table.h

# --- Tools and Apps ---

MUTOOL := $(addprefix $(OUT)/, mutool)
MUTOOL_OBJ := $(addprefix $(OUT)/tools/, mutool.o mudraw.o murun.o pdfclean.o pdfcreate.o pdfextract.o pdfinfo.o pdfposter.o pdfshow.o pdfpages.o)
$(MUTOOL_OBJ): $(FITZ_HDR) $(PDF_HDR)
$(MUTOOL) : $(UVIEW_LIB) $(THIRD_LIB)
$(MUTOOL) : $(MUTOOL_OBJ)
	$(LINK_CMD)

MJSGEN := $(OUT)/mjsgen
$(MJSGEN) : $(UVIEW_LIB) $(THIRD_LIB)
$(MJSGEN) : $(addprefix $(OUT)/tools/, mjsgen.o)
	$(LINK_CMD)

MUJSTEST := $(OUT)/mujstest
MUJSTEST_OBJ := $(addprefix $(OUT)/platform/x11/, jstest_main.o pdfapp.o)
$(MUJSTEST_OBJ) : $(FITZ_HDR) $(PDF_HDR)
$(MUJSTEST) : $(UVIEW_LIB) $(THIRD_LIB)
$(MUJSTEST) : $(MUJSTEST_OBJ)
	$(LINK_CMD)

ifeq "$(HAVE_X11)" "yes"
 # --- uview-x11 ---
 UVIEW_X11 := $(OUT)/uview-x11
 UVIEW_X11_OBJ := $(addprefix $(OUT)/platform/x11/, x11_main.o x11_image.o pdfapp.o)
 $(UVIEW_X11_OBJ) : $(FITZ_HDR) $(PDF_HDR)
 $(UVIEW_X11) : $(UVIEW_LIB) $(THIRD_LIB)
 $(UVIEW_X11) : $(UVIEW_X11_OBJ)
	$(LINK_CMD) $(X11_LIBS)

 ifeq "$(HAVE_GLFW)" "yes"
  # --- uview-gl ---
  UVIEW_GLFW := $(OUT)/uview-gl
  UVIEW_GLFW_OBJ := $(addprefix $(OUT)/platform/gl/, gl-font.o gl-input.o gl-main.o)
  $(UVIEW_GLFW_OBJ) : $(FITZ_HDR) $(PDF_HDR) platform/gl/gl-app.h
  $(UVIEW_GLFW) : $(UVIEW_LIB) $(THIRD_LIB) $(GLFW_LIB)
  $(UVIEW_GLFW) : $(UVIEW_GLFW_OBJ)
	$(LINK_CMD) $(GLFW_LIBS)
 endif

 ifeq "$(HAVE_CURL)" "yes"
  # --- uview-x11-curl ---
  UVIEW_X11_CURL := $(OUT)/uview-x11-curl
  UVIEW_X11_CURL_OBJ := $(addprefix $(OUT)/platform/x11/curl/, x11_main.o x11_image.o pdfapp.o curl_stream.o)
  $(UVIEW_X11_CURL_OBJ) : $(FITZ_HDR) $(PDF_HDR)
  $(UVIEW_X11_CURL) : $(UVIEW_LIB) $(THIRD_LIB) $(CURL_LIB)
  $(UVIEW_X11_CURL) : $(UVIEW_X11_CURL_OBJ)
	$(LINK_CMD) $(X11_LIBS) $(CURL_LIBS) $(SYS_CURL_DEPS)
 endif
endif

ifeq "$(HAVE_WIN32)" "yes"
 # --- for debugging ---
 VB6_INSTALL_PATH := C:\Program Files\VB simplified
 
 #
 # --- uview ---
 #
 UVIEW_WIN32 := $(OUT)/uview
 UVIEW_WIN32_OBJ := $(addprefix $(OUT)/platform/x11/, win_main.o pdfapp.o)
 $(UVIEW_WIN32_OBJ) : $(FITZ_HDR) $(PDF_HDR)
 $(UVIEW_WIN32) : $(UVIEW_LIB) $(THIRD_LIB)
 $(UVIEW_WIN32) : $(UVIEW_WIN32_OBJ)
	$(LINK_CMD) $(WIN32_LIBS)

 #
 # --- libuview ---
 #
 UVIEW_VB6 := $(OUT)/libuview.dll
 UVIEW_VB6_OBJ := $(addprefix $(OUT)/platform/vb6/, libuview.o)
 $(UVIEW_VB6_OBJ): $(FITZ_HDR) $(PDF_HDR) platform/vb6/libuview.h
 $(UVIEW_VB6): $(UVIEW_LIB) $(THIRD_LIB)
 $(UVIEW_VB6): $(UVIEW_VB6_OBJ)
	$(LINK_CMD) -shared -Wl,--output-def,$(basename $@).def,--out-implib,$(basename $@).a,--kill-at
# for debugging
	-cp $@ "$(VB6_INSTALL_PATH)"
endif

UVIEW := $(UVIEW_X11) $(UVIEW_WIN32) $(UVIEW_VB6) $(UVIEW_GLFW)
UVIEW_CURL := $(UVIEW_X11_CURL) $(UVIEW_WIN32_CURL)

INSTALL_APPS := $(MUTOOL) $(UVIEW) $(MUJSTEST) $(UVIEW_CURL)

# --- Examples ---

examples: $(OUT)/example $(OUT)/multi-threaded

$(OUT)/example: docs/example.c $(UVIEW_LIB) $(THIRD_LIB)
	$(LINK_CMD) $(CFLAGS)
$(OUT)/multi-threaded: docs/multi-threaded.c $(UVIEW_LIB) $(THIRD_LIB)
	$(LINK_CMD) $(CFLAGS) -lpthread

# --- Update version string header ---

VERSION = $(shell git describe --tags)

version:
	sed -i~ -e '/FZ_VERSION /s/".*"/"'$(VERSION)'"/' include/uview/fitz/version.h

# --- Format man pages ---

%.txt: %.1
	nroff -man $< | col -b | expand > $@

MAN_FILES := $(wildcard docs/man/*.1)
TXT_FILES := $(MAN_FILES:%.1=%.txt)

catman: $(TXT_FILES)

# --- Install ---

prefix ?= /usr/local
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
incdir ?= $(prefix)/include
mandir ?= $(prefix)/share/man
docdir ?= $(prefix)/share/doc/uview

third: $(THIRD_LIB)
fonts: $(FONTS_LIB)
extra: $(CURL_LIB) $(GLFW_LIB)
libs: $(INSTALL_LIBS)
apps: $(INSTALL_APPS)

install: libs apps
	install -d $(DESTDIR)$(incdir)/uview
	install -d $(DESTDIR)$(incdir)/uview/fitz
	install -d $(DESTDIR)$(incdir)/uview/pdf
	install include/uview/*.h $(DESTDIR)$(incdir)/uview
	install include/uview/fitz/*.h $(DESTDIR)$(incdir)/uview/fitz
	install include/uview/pdf/*.h $(DESTDIR)$(incdir)/uview/pdf

	install -d $(DESTDIR)$(libdir)
	install $(INSTALL_LIBS) $(DESTDIR)$(libdir)

	install -d $(DESTDIR)$(bindir)
	install $(INSTALL_APPS) $(DESTDIR)$(bindir)

	install -d $(DESTDIR)$(mandir)/man1
	install docs/man/*.1 $(DESTDIR)$(mandir)/man1

	install -d $(DESTDIR)$(docdir)
	install README COPYING CHANGES docs/*.txt $(DESTDIR)$(docdir)

tarball:
	bash scripts/archive.sh

# --- Clean and Default ---

java:
	$(MAKE) -C platform/java

tags: $(shell find include src platform libs -name '*.[ch]' -or -name '*.cc' -or -name '*.hh')
	ctags $^

cscope.files: $(shell find include src platform -name '*.[ch]')
	@ echo $^ | tr ' ' '\n' > $@

cscope.out: cscope.files
	cscope -b

all: libs apps

clean:
	rm -rf $(OUT)
    
nuke:
	rm -rf build/* $(GEN) $(NAME_GEN)

release:
	$(MAKE) build=release
debug:
	$(MAKE) build=debug

.PHONY: all clean nuke install third fonts libs apps generate
