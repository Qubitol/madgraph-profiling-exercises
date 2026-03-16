# =============================================================================
# Makefile for building the exercise document
# Requires: xelatex, latexmk, magick (ImageMagick)
# Fonts: Fira Sans, FiraCode NF, Fira Math (system-installed)
# =============================================================================

MAIN      = exercises
DIAGRAM   = figures/choice-diagram
LATEXMK   = latexmk -xelatex -interaction=nonstopmode -halt-on-error

.PHONY: all clean distclean diagram pdf

all: pdf

# ── Build the choice diagram as standalone PDF, then convert to PNG ──────────
diagram: $(DIAGRAM).png

$(DIAGRAM).pdf: $(DIAGRAM).tex
	cd figures && xelatex -interaction=nonstopmode choice-diagram.tex

MAGICK := $(shell command -v magick 2>/dev/null || command -v convert 2>/dev/null)

$(DIAGRAM).png: $(DIAGRAM).pdf
ifndef MAGICK
	$(error Neither "magick" nor "convert" found. Install ImageMagick.)
endif
	$(MAGICK) -density 300 $(DIAGRAM).pdf -quality 95 $(DIAGRAM).png

# ── Build the main document ──────────────────────────────────────────────────
pdf: $(MAIN).pdf

$(MAIN).pdf: $(MAIN).tex preamble.tex $(DIAGRAM).png
	$(LATEXMK) $(MAIN).tex

# ── Clean auxiliary files ────────────────────────────────────────────────────
clean:
	latexmk -c $(MAIN).tex
	cd figures && rm -f choice-diagram.aux choice-diagram.log choice-diagram.fls \
		choice-diagram.fdb_latexmk choice-diagram.synctex.gz

# ── Clean everything including PDFs ──────────────────────────────────────────
distclean: clean
	latexmk -C $(MAIN).tex
	rm -f $(DIAGRAM).pdf $(DIAGRAM).png
