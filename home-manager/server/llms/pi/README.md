# pi config (declarative)

Wired into `~/.pi/agent/` by `../pi-config.nix`. Edit here, then rebuild —
never edit `~/.pi/agent/{prompts,skills,extensions,themes}` directly (they are
read-only nix-store symlinks).

- `prompts/`     — Markdown prompt templates, expand with `/name` (one `<name>.md` per template)
- `skills/`      — Agent Skills, one `<skill>/SKILL.md` subdir each, invoke via `/skill:name`
- `extensions/`  — TypeScript extensions (`*.ts`) — custom tools, commands, UI, hooks
- `themes/`      — custom themes. `system.json` is NOT here: it is generated
  from the active palette by `../pi-config.nix` and joined into this dir at
  build time (see `piThemesDir` there). Edit the palette, not a checked-in file.

`.gitkeep` keeps each dir tracked while empty; pi ignores dotfiles so they load
nothing. Managed `settings.json` defaults live in `../pi-config.nix` (jq-merged,
not symlinked, so pi can still persist `/settings` at runtime). Secrets/runtime
state (`auth.json`, `models-store.json`, `sessions/`) stay machine-local and are
NOT managed.
