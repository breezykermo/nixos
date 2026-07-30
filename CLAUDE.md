# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Note**: This project uses beads for issue tracking via the `br` CLI. Global process rules (including beads workflow, version control conventions, and pi behavior) are in `home-manager/server/llms/global-agents.md` — follow those.

## Overview

This is a personal NixOS configuration using flakes and home-manager. The configuration is designed for the user "lox" on a Framework laptop (hostname: "loxnix"), with support for both desktop (Wayland/Hyprland) and server environments.

## Build and Deploy Commands

All commands are managed via the `Justfile`:

- `just deploy` - Apply configuration changes to the system (runs `nixos-rebuild switch --flake . --sudo`)
- `just debug` - Deploy with verbose output and stack traces for debugging
- `just up` - Update all flake inputs to their latest versions
- `just upp i=<input-name>` - Update a specific flake input (e.g., `just upp i=home-manager`)
- `just history` - View system profile history
- `just clean` - Remove generations older than 1 day
- `just gc` - Garbage collect unused nix store entries

**IMPORTANT**: The user will ALWAYS deploy manually. Do NOT attempt to run `just deploy` or any deployment commands. Only make the necessary configuration file changes and let the user handle deployment.

## Architecture

### Flake Structure

The repository uses a flake-based configuration (`flake.nix`) with the following key inputs:
- `nixpkgs` (nixos-unstable channel)
- `home-manager` for user-level package management
- `ghostty` for the terminal emulator
- `naersk` for building Rust packages

The flake exposes one `nixosConfigurations.<machine>` per directory under `machines/`
(auto-discovered: `framework`, `homework`, `dellxps`). Each combines:
- Base system configuration (`configuration.nix`)
- Shared machine base (`machines/base.nix`)
- Machine-specific config (`machines/<machine>/configuration.nix`)
- Home-manager configuration for the user

### Configuration Organization

The configuration is split into two main domains:

1. **System-level** (`configuration.nix`): Network, users, fonts, virtualization, hardware, XDG portal setup
2. **User-level** (`home-manager/`): Split into two categories:
   - `server/`: CLI tools, terminal configurations (fish, tmux, neovim, core utilities)
   - `desktop/`: GUI applications (Hyprland, browsers, Spotify, OBS, gaming, etc.)

### Home-Manager Structure

- `home-manager/default.nix` - Entry point, imports both server and desktop modules
- `home-manager/server/core.nix` - Essential CLI tools and shell aliases (ripgrep, fd, jq, lazygit, git, jujutsu, fzf, etc.)
- `home-manager/server/` - Shell (fish), multiplexer (tmux), editor (neovim), IRC client
- `home-manager/desktop/` - Desktop environment (Hyprland), applications organized by function

Each application domain has its own subdirectory under `home-manager/{server,desktop}/` with a `default.nix` file.

## Key Configuration Details

### User and Hostname
- Username is per-machine, from `machines/<machine>/vars.nix` (`lox` on framework/homework,
  `alice` on dellxps)
- Hostname is per-machine, from `machines/<machine>/vars.nix` (`loxnix` on framework/homework,
  `dellxps` on dellxps); applied as `networking.hostName` in `configuration.nix`

### Machine-Specific Configurations
Each machine has its own directory under `machines/` (`framework`, `homework`, `dellxps`)
containing `configuration.nix`, `hardware-configuration.nix`, and `vars.nix`. A config
includes the hardware config and machine-specific services (power management, hardware
support, etc.).

`flake.nix` auto-discovers these directories (`builtins.readDir ./machines`, excluding the
regular files `base.nix`/`local-profile.nix` and the shared `modules/` dir) and exposes each
as `nixosConfigurations.<machine>` simultaneously — there is NO hardcoded machine selection.
The machine name is also passed to shared modules as `localProfile`, used to gate
machine-specific software/behaviour (e.g. `localProfile == "homework"` checks).

**Build-time selection.** Which machine gets built is chosen with the flake attr:
`nixos-rebuild switch --flake .#<machine>`. `just deploy`/`just debug` fill this in by reading
the gitignored per-box marker `machines/local-profile.nix` (e.g. `"framework"`). This resolves
the old eval-time constraint: `flake.nix` still can't read a gitignored selector (flakes only
see git-tracked files at eval time), but the `Justfile` runs at DEPLOY time, so it CAN read the
marker and pass it as the attr. Each box keeps its own `local-profile.nix`; there is no shared
`hostname = "loxnix"` workaround anymore (dellxps freely uses `hostname = "dellxps"` /
`userName = "alice"`).

### Secrets Management
Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) and decrypt
automatically at activation (no manual unlock). See `docs/secrets.md`.

### Neovim Configuration

The Neovim configuration is split between two files:
- `home-manager/server/editor/neovim/default.nix` - Package definitions and plugin list
- `home-manager/server/editor/neovim/init.lua` - Neovim configuration (loaded directly via `:luafile`)

**IMPORTANT**: When editing `init.lua`, you do NOT need to run `just deploy`. The file is loaded directly by Neovim at startup (see `extraConfig` in `default.nix`), so changes take effect immediately when you restart Neovim. Only run `just deploy` when modifying `default.nix` (packages, plugins, etc.).

### Manual Setup Steps

After initial deployment:
1. Run `Hyprland` to start the desktop environment

## Important Files

- `flake.nix` - Flake configuration with inputs and system definition
- `configuration.nix` - System-wide configuration (network, users, hardware, fonts)
- `machines/{framework,dellxps}/configuration.nix` - Machine-specific settings
- `home-manager/default.nix` - User configuration entry point
- `home-manager/server/core.nix` - Core CLI tools and shell configuration
- `themes/default.nix` - Centralized theme configuration (see THEMING.md)
- `Justfile` - Build and maintenance commands
- `THEMING.md` - Complete guide to the theme system

## Conventions

- Allow unfree packages globally (`nixpkgs.config.allowUnfree = true`)
- Use flakes and nix-command experimental features
- Automatic garbage collection runs weekly
- Auto-optimize nix store is enabled
- Default shell: Fish (enabled system-wide)
- Default editor: Set via `$EDITOR` environment variable
- Git default branch: `main`
- Version control: Both `git` and `jujutsu` (jj) are configured
- Package source preference: prefer an existing flake input if the package is already available via one; otherwise use a mature `nixpkgs` package; only build from source as a last resort

## Issue Tracking (br/beads)

All process rules for beads/br are in the global-level memory file at `home-manager/server/llms/global-agents.md` — **follow those**, not simplified duplicates here. Key points:

- Use `br` (not `bd`) for all issue tracking commands with `--json`. `.beads/` is gitignored.
- Always end jj work with an empty unnamed `@` on top.
- Label convention: alphanumeric/hyphen/underscore only (no `/`). Use hyphen form for labels, slash for bookmarks.

---

## Process: "Update global CLAUDE devenvs"

The global (user-level) CLAUDE.md source lives at
`home-manager/server/llms/global-agents.md` in this repo (symlinked to `~/.claude/CLAUDE.md` by
home-manager). Its **Development Environment (NixOS + flake devShells)** section documents the
per-stack devShell setup, distilled from a set of canonical example projects.

When the user says **"Update global CLAUDE devenvs"** (or close variant), do this:

1. Read the current **Development Environment** section in
   `home-manager/server/llms/global-agents.md` — note the canonical example projects listed at
   the end of it (currently OxCaml `~/code/_karaji/karaji`, Rust `~/code/_rheo/rheo`, Python
   `~/code/_pragma/pragma`).
2. Read each canonical project's `flake.nix` (and `.envrc` if relevant). Skip any that no longer
   exist on this machine and note which were skipped.
3. Re-derive the **generalized** per-stack description from what the flakes actually do now —
   the two-layer split (Nix = system layer; language package manager = language layer,
   project-local, activated by the devShell `shellHook`), the pinned toolchain, native deps,
   and any build-sandbox caveats. Keep it stack-general, NOT project-specific: the section must
   still make sense on a machine where those projects are absent.
4. Edit only that section of `global-agents.md` to match. Preserve the surrounding structure and
   the "live examples … may not exist on every machine" note.
5. Report what changed per stack (and any projects skipped as missing).

Do NOT deploy — the user rebuilds home-manager themselves to re-link the file.
