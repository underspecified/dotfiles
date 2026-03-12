# Markdown / Quarto Conventions

## Heading Hierarchy

| Context | `#` | `##` | `###` | `####` |
|---------|-----|------|-------|--------|
| Papers (PDF) | Main sections | Subsections | Sub-subsections | — |
| Proposals (DOCX) | Reserved for title | Sections | Subsections | Sub-subsections |
| Slides (PPTX/RevealJS) | — | Slide title | — | — |

## Inline Formatting

- `==text==` highlighting (requires `from: markdown+mark`, `mark.lua` + `highlight-text` filter)
- `**bold**`, `*italic*`, `~subscript~` (e.g., `M~t~`)
- `$math$` for inline LaTeX (e.g., `$t(22)=1.29$`, `$p=.212$`, `$N=23$`)
- `_"quoted text"_ (P03)` for participant quotes in papers

## Lists

- `-` unordered, `1.` ordered, 2-space indent for nesting
- `**Bold label:**` pattern for definition-style items

## Figures

Standard Quarto syntax:

```markdown
![Caption text](assets/figure.png){#fig-id}
```

- IDs: kebab-case with `fig-` prefix, cross-ref with `@fig-id`
- Paths: relative to document (`assets/`, `figs/`)
- Dual format: PDF for LaTeX/print, PNG for web/preview
- R figures: use `cairo_pdf` device for automatic font embedding

LaTeX figures (ACM 2-column):

```latex
\includegraphics[width=1.0\columnwidth,alt={Description}]{figs/file.pdf}
```

Always include `alt={...}` for accessibility (processed by `fancy-figure.lua` into `\Description{}`).

## Tables

Pipe-delimited with alignment markers:

```markdown
| Left        | Right |
| :---------- | ----: |
| content     |  1.29 |

: Caption text. {#tbl-id tbl-colwidths="[30,70]" tbl-align="left"}
```

- Cross-ref: `@tbl-id`
- `<br><br>` for in-cell line breaks (requires `linebreaks.lua`)
- Custom styles via `table-styles.lua` at `post-render` (content-based detection)
- ACM 2-column: `fix-longtable.lua` converts to raw LaTeX `tabular`

## Citations

```markdown
[@nichols2022believe]              # standard parenthetical
[-@nichols2022believe]             # suppress author (authorial)
[@venture2019; @karg2013]          # multiple
Wang et al. [@wang2024aint]        # narrative with parenthetical
```

- BibTeX keys: `authorYYYYkeyword` (e.g., `nichols2022believe`)
- **Always verify entries via CrossRef** -- never trust AI-generated bibliography
- Bibliography section at doc end: `::: {#refs} :::`

## Slides (PPTX / RevealJS)

- `---` separator between slides, `##` slide title
- Multi-column: `:::: {.columns}` / `::: {.column width="50%"}`
- Speaker notes: `::: {.notes}`
- Reference template: `reference-doc:` in YAML frontmatter

## YAML Frontmatter Patterns

**DOCX:**

```yaml
format:
  docx:
    from: markdown+mark
    reference-doc: template.dotx
filters:
  - mark.lua
  - highlight-text
  - linebreaks.lua
  - at: post-render
    path: table-styles.lua
bibliography: references.bib
```

**ACM PDF:**

```yaml
format:
  acm-pdf:
    latex-auto-install: false
    code-overflow: wrap
filters:
  - fix-longtable.lua
bibliography: references.bib
include-in-header: acm-sigconf.tex
acm-metadata:
  anonymous: false
  final: true
  documentclass: acmart-tagged
  acmart-options: sigconf,screen
  teaser:
    image: figs/architecture.pdf
    width: 0.8\textwidth
    caption: "Caption text."
    description: "Alt text for accessibility."
```

**PPTX:**

```yaml
format:
  pptx:
    reference-doc: templates/template.pptx
from: markdown+mark
filters:
  - mark.lua
  - highlight-text
```

## Build and Rendering

```bash
quarto render file.qmd [--to format]
```

- Build scripts: `build.sh` in each document directory
- Post-processing: `fix_docx.py`, `fix_pptx.py` for OOXML corruption fixes
- `QUARTO_LATEX_AUTO_INSTALL=false` to prevent `tlmgr` hangs
- `-M keep-tex:true --debug` for LaTeX troubleshooting

## Templates and Extensions

- DOCX templates: `.dotx` files via `reference-doc:`
- PPTX templates: stored in `templates/`, named `YYYYMMDD_Description.pptx`
- Extensions: centralized in `quarto/extensions/_extensions/`, symlinked into document dirs
- Filters: centralized in `quarto/filters/`, symlinked into document dirs
- **Symlinks always use relative paths**

## Filters

Ordering matters -- listed in execution order:

| Filter | Purpose | Stage |
|--------|---------|-------|
| `mark.lua` | Convert `==text==` to highlight spans | default (before highlight-text) |
| `highlight-text` | Apply background color to marked text | default |
| `linebreaks.lua` | Convert `<br>` tags to DOCX line breaks | default |
| `fix-longtable.lua` | Convert tables to raw LaTeX `tabular` for ACM 2-column | default |
| `table-styles.lua` | Apply custom Word table styles by content detection | `post-render` |

## Project Layout Pattern

```
project/
├── paper/ or proposal/    # Main document + build.sh + references.bib + assets/
├── slides/                # Presentations + templates/
├── quarto/                # Shared extensions/ and filters/ (symlinked)
├── figures/               # Generated figures (separate build)
├── analysis/              # R/Python analysis scripts
└── CLAUDE.md
```
