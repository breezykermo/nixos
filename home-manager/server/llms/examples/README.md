# Reusable examples (the hoard)

A cross-machine, version-controlled hoard of small, self-contained working
examples — commands, config snippets, code patterns, prompts — so that a useful
trick only ever has to be figured out once.

It lives here in the NixOS config repo (`/etc/nixos/home-manager/server/llms/examples/`)
**on purpose**: the repo is synced to every machine, so anything added here
persists everywhere. Do **not** put the hoard in `~/.claude/` — that is
machine-local and would not travel.

## For agents

- **Before** solving a known-shaped problem, search the hoard first:
  `rg -l <keyword> /etc/nixos/home-manager/server/llms/examples` — reusing a working example is faster and
  more reliable than starting cold. Building something new by combining two or
  more existing examples is a great default.
- **After** you crack something reusable (a gnarly command, a config pattern, an
  API dance, an effective prompt), add it here. See "How to add an example".

## How to add an example

1. Create `/etc/nixos/home-manager/server/llms/examples/<kebab-case-slug>.md`.
2. Fill in the frontmatter and body using the template below. Keep the example
   **minimal and self-contained**: copy-pasteable, with no placeholders that
   require further investigation to use.
3. Add one line to the Index below:
   `- [Title](slug.md) — one-line hook`.
4. That's it — no Nix wiring is needed. Commit it with the rest of your work so
   it syncs to the other machines.

## Format

Each example is one Markdown file with YAML frontmatter, a fenced code block
holding the working example, and optional notes:

````markdown
---
title: Short human title
when: The situation in which you'd reach for this
tags: [area, tool, topic]
---

```bash
# the minimal working example — command / config / code
```

Notes: anything non-obvious (why it works, gotchas, where the inputs come from).
````

## Index

- [Unlock git-crypt secrets](git-crypt-unlock.md) — decrypt this repo's secrets after a fresh checkout
