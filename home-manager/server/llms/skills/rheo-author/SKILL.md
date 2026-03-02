---
name: rheo-author
description: Author, configure, and build rheo projects. Use when working with rheo.toml, *.typ content files in a rheo project, or running rheo build/watch commands.
---

# rheo-author skill

## Overview

Rheo is a Typst-based static site / multi-format publishing engine (written in Rust). It compiles `.typ` source files into **HTML, PDF, and EPUB** simultaneously from a single source. Repository: https://github.com/freecomputinglab/rheo

Key properties:
- Single `.typ` source → multiple output formats
- HTML output is a proper static site (one `.html` per `.typ` file)
- Per-format conditional rendering via `target()` inside `context`
- Auto-injects a small `rheo.typ` helper into every compiled file (no import needed)
- CSS and `content/img/` are auto-copied to `build/html/`; fonts are **not** auto-copied

---

## Minimal project example

```
myproject/
├── rheo.toml
├── style.css
└── content/
    └── index.typ
```

**`rheo.toml`:**
```toml
version = "0.1.2"   # must match installed CLI exactly
content_dir = "content"

[pdf.spine]
title = "My Project"
vertebrae = ["index.typ"]
merge = true
```

**`content/index.typ`:**
```typst
#set document(title: "My Project")

= Hello, Rheo

This content renders as HTML, PDF, and EPUB.

#context if target() == "html" [
  This paragraph only appears in HTML output.
]
```

---

## Workflows

### New project
```bash
rheo init myproject
cd myproject
# Edit rheo.toml and content/ files
rheo compile myproject --html
```

### Adding a page
1. Create `content/newpage.typ`
2. If using a shared template, import and apply it:
   ```typst
   #import "index.typ": template
   #show: template.with(current-page: "newpage")
   ```
3. Add to `[pdf.spine]` and `[epub.spine]` vertebrae if needed
4. Add a nav entry in your template function

### Building
```bash
rheo compile myproject                # all formats (HTML, PDF, EPUB)
rheo compile myproject --html         # HTML only
rheo compile myproject --pdf          # PDF only
rheo compile myproject --epub         # EPUB only
```

### Watching (dev server)
```bash
rheo watch myproject --open           # recompile on save + open localhost:3000
rheo watch myproject                  # recompile without opening browser
```

---

## rheo.toml reference

```toml
version = "0.1.2"           # Required. Must match CLI version exactly.
content_dir = "content"     # Where .typ files live. Default: entire project root.
build_dir = "./build"        # Output root. Default: ./build
formats = ["html", "pdf", "epub"]  # Default formats when no CLI --flag given.

[html]
stylesheets = ["style.css"] # CSS files copied into build/html/ and injected into <head>.
fonts = []                  # External font URLs to inject in <head>.

[html.spine]                # Optional. Doesn't merge; still produces per-file output.
vertebrae = ["index.typ"]

[pdf.spine]
title = "My Book"
vertebrae = ["cover.typ", "chapters/**/*.typ"]  # Glob patterns supported.
merge = true                # true = single merged PDF. false (default) = per-file PDFs.

[epub]
identifier = "urn:uuid:..."  # Optional. Auto-generated if omitted.
date = "2025-01-01"          # ISO 8601.

[epub.spine]
title = "My Book"
vertebrae = ["index.typ", "chapter2.typ"]  # EPUB always merges.
```

**Config precedence (highest → lowest):** CLI flags > `rheo.toml` > built-in defaults

---

## Typst authoring patterns for rheo

### Format detection

`target()` is context-sensitive and must be called inside `context`:

```typst
context if target() == "html" {
  [HTML-only content]
} else if target() == "epub" {
  [EPUB content]
} else {
  [PDF content]
}
```

Auto-injected helpers (no import needed):
```typst
rheo-target()      // returns "html", "epub", or "pdf"
is-rheo-html()     // bool
is-rheo-epub()     // bool
is-rheo-pdf()      // bool
```

### Creating HTML elements with attributes

```typst
html.elem("nav", attrs: (class: "site-nav"))[content here]
html.elem("div", attrs: (class: "card"))[...]
html.elem("span", attrs: (class: "label"))[#value]
html.elem("hr")
html.elem("ul")[
  #html.elem("li")[item one]
  #html.elem("li")[item two]
]
```

### Shared template with navigation

Define in one file (e.g. `index.typ`), import in others:

```typst
#let template(current-page: none, doc) = {
  context if target() == "html" {
    html.elem("nav", attrs: (class: "site-nav"))[
      #let pages = (
        (id: "index",    title: "Home",     file: "./index.html"),
        (id: "about",    title: "About",    file: "./about.html"),
      )
      #html.elem("ul")[
        #for p in pages {
          let cls = if p.id == current-page { "active" } else { "" }
          html.elem("li", attrs: (class: cls))[
            #link(p.file)[#p.title]
          ]
        }
      ]
    ]
    html.elem("hr")
  }
  doc
}
```

Apply with a `#show:` rule:
```typst
#import "index.typ": template
#show: template.with(current-page: "about")
```

### Component with HTML + print fallback

```typst
#let person(name, role: none, body) = {
  context if target() == "html" {
    html.elem("div", attrs: (class: "person"))[
      #if role != none [*#name* --- #emph(role)] else [*#name*]
      #body
    ]
  } else {
    if role != none [*#name* --- #emph(role)] else [*#name*]
    body
  }
}
```

### Cross-document links

Rheo automatically transforms `.typ` references to `.html` in HTML output:
```typst
#link("./about.typ")[About]         // → ./about.html in HTML
#link("./page.typ#section")[...]    // fragment links also transformed
```

---

## CLI commands

```bash
# Compile
rheo compile PROJECT [--html] [--pdf] [--epub]
         [--config FILE] [--build-dir DIR]
         [-v|--verbose] [-q|--quiet]

# Watch (incremental rebuild + optional dev server)
rheo watch PROJECT [--html] [--pdf] [--epub] [--open]

# Clean build artifacts
rheo clean [PROJECT] [--build-dir DIR]

# Initialize a new project
rheo init PROJECT_NAME

# Version
rheo --version
```

---

## Asset management

| Asset | Auto-copied? | Location in build |
|---|---|---|
| `style.css` (project root) | Yes | `build/html/style.css` |
| `content/img/**` | Yes | `build/html/img/` |
| `fonts/**` | **No** | Must copy manually |

Copying fonts after a build:
```bash
rheo compile myproject --html
cp -r fonts/ build/html/fonts/
```

CSS `@font-face` paths should be relative to `build/html/style.css`:
```css
@font-face {
  font-family: 'Berkeley Mono';
  src: url('./fonts/BerkeleyMono-Regular.ttf') format('truetype');
}
```

---

## Auto-injected rheo.typ

Every `.typ` file gets this prepended automatically (do not import it):

```typst
#let rheo-target() = {
  if "rheo-target" in sys.inputs { sys.inputs.rheo-target }
  else { target() }
}
#let is-rheo-epub() = "rheo-target" in sys.inputs and sys.inputs.rheo-target == "epub"
#let is-rheo-html() = "rheo-target" in sys.inputs and sys.inputs.rheo-target == "html"
#let is-rheo-pdf()  = "rheo-target" in sys.inputs and sys.inputs.rheo-target == "pdf"

#set text(font: "Libertinus Serif")  // default — override in your file
```

Override the default font early in your file:
```typst
#set text(font: "Inter", size: 11pt)
```

---

## Common mistakes

- **Version mismatch** — `version` in `rheo.toml` must match `rheo --version` exactly. Error looks like: `rheo.toml version "0.1.1" does not match CLI version "0.1.2"`. Fix: update the `version` field.
- **Unclosed content block** — using `\]` instead of `]` inside `html.elem(...)[...]` escapes the bracket literally, leaving the block unclosed. Always close with plain `]`.
- **`target()` outside context** — calling `target()` without a surrounding `context` block causes a compile error. Wrap: `context if target() == "html" { ... }`.
- **Fonts missing in HTML output** — fonts are not auto-copied. Run `cp -r fonts/ build/html/fonts/` after building.
- **Wrong spine for EPUB** — EPUB always merges; the `[epub.spine]` section is required if you want a specific file order.
- **Importing rheo.typ helpers** — do not `#import` them; they are injected automatically and will error if imported.

---

## Troubleshooting

### Blank or empty HTML output
- Verify `content_dir` in `rheo.toml` points to the correct directory.
- Check that `.typ` files don't have top-level `#set page(...)` calls with `margin: 0pt` (PDF-specific settings can suppress HTML output in some versions).
- Run with `--verbose` to see which files are processed.

### Fonts not loading in browser
1. Confirm font files are in `build/html/fonts/` (copy them manually after each build).
2. Check `@font-face` `src:` paths are relative to `build/html/style.css`.
3. Open browser DevTools → Network → filter for font files to see 404s.

### Version error on compile
```
Error: rheo.toml specifies version X but CLI is version Y
```
Update `version = "Y"` in `rheo.toml` to match the installed CLI.

### `target` is not defined
You are calling `target()` outside a `context` block. Typst's `target()` function is context-sensitive. Always wrap:
```typst
context if target() == "html" { ... }
```

### CSS not applied
`style.css` must be in the project root (same level as `rheo.toml`), not inside `content/`. Or set `[html] stylesheets = ["path/to/file.css"]` explicitly.
