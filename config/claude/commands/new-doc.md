# new-doc

Create a new Markdown document pre-formatted for the `md-to-pdf` converter — a
general-purpose Markdown → PDF tool that produces a cover page, a navigable table
of contents, automatic figure/table/code-block indices, page headers/footers, and
PDF bookmarks. It suits reports, manuals, notes, or any structured document (not
just academic work).

## Usage

```
/new-doc filename.md
/new-doc filename.md "Document Title" "Subtitle" "Author Name"
```

All arguments after the filename are optional — Claude will ask for any missing ones.

## Format reference

The document starts with a **YAML front matter** block delimited by `---` lines,
followed by the **body**:

1. **Front matter** (between the `---` lines): `key: value` metadata.
2. **Body** (after the closing `---`): sections as `## 1. Name`, subsections as `### 1.1 Name`.

Recognized front-matter keys (all optional except `title`; English/Spanish aliases work):
- `title` — shown large on the cover and in the page header.
- `subtitle` — italic line under the title; also shown in the header.
- `comment` — a free extra line on the cover (e.g. a date, course, or note).
- `author` — shown on the cover and in the page footer.
- `logo` — path to **any** image to center on the cover (relative to the `.md`).
  Use `logo: none` to disable auto-detection. If omitted, a `logo.*` file next to
  the `.md` is used automatically when present.
- `locale` — `es` (default) or `en`; controls the wording of "Figura/Figure",
  "Tabla/Table", index titles, etc.
- `code_theme` — palette for code-syntax highlighting. Empty/`custom` uses the
  built-in warm palette (soft browns + oranges); otherwise any Pygments theme
  name (`monokai`, `dracula`, `github-dark`, `solarized-light`, `nord`…).

Rules for the body:
- `## ` headings trigger a new page; `### ` subsections do not.
- The TOC and per-type indices (figures, tables, code blocks) are generated automatically.
- Lists use `-` as marker; **no blank lines between items** in the same list.
- **Every** image, table, and code block must have a description, or the converter
  refuses to produce the PDF. Add `<!-- caption: text -->` on the line immediately
  before the element; for images, the alt-text also counts as the description.
- Labels become "Figura/Figure x.y", "Tabla/Table x.y", "Bloque de código/Code block x.y";
  counters reset at each `##`.
- Put `<!-- keep -->` on the line before an element to force it to stay on the same
  page as the preceding content (it may split across pages instead of being pushed down).
- A code block can override the document's `code_theme` with `<!-- code-theme: NAME -->`
  on the line just before its ``` fence (placed below any `<!-- caption: -->`), so
  different blocks can use different palettes in the same document.

For the full reference (all front-matter keys, code-highlight palettes/themes, and
how to customize the warm palette) see the converter's README: `~/md-to-pdf/README.md`.

## Steps

1. Parse `$ARGUMENTS`: first token is the output filename; remaining tokens (if any)
   are title, subtitle, author — in that order.
2. For any of title / subtitle / author not supplied, ask the user. Subtitle and
   author may be left blank. Ask for `locale` only if unclear (default `es`).
3. Write the file with this skeleton (substitute real values; omit any front-matter
   line whose value is blank):

```
---
title: {title}
subtitle: {subtitle}
author: {author}
locale: es
---

## 1. Introducción

Escribe aquí el contenido de la primera sección.

### 1.1 

```

4. After writing, tell the user:
   - The file path that was created.
   - A one-line reminder of the key rules: numbered `##` sections, `-` lists with no
     blank lines between items, and a required `<!-- caption: text -->` (or image
     alt-text) before every figure/table/code block.
   - That they can convert it with: `md-to-pdf {filename}`
