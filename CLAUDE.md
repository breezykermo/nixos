# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

## Architecture

### Flake Structure

The repository uses a flake-based configuration (`flake.nix`) with the following key inputs:
- `nixpkgs` (nixos-unstable channel)
- `home-manager` for user-level package management
- `ghostty` for the terminal emulator
- `naersk` for building Rust packages

The main system configuration is `nixosConfigurations.loxnix`, which combines:
- Base system configuration (`configuration.nix`)
- Machine-specific config (`machines/framework/configuration.nix` or `machines/dellxps/configuration.nix`)
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
- Current username: `lox` (configurable in `flake.nix`)
- Hostname: `loxnix` (defined in `configuration.nix`)
- The hostname in the flake must match the system hostname for deployment to work

### Machine-Specific Configurations
Toggle between machines by commenting/uncommenting imports in `flake.nix:36-37`:
```nix
./machines/framework/configuration.nix
# ./machines/dellxps/configuration.nix
```

Each machine config includes hardware-configuration and machine-specific services (power management, hardware support, etc.).

### Secrets Management
Uses `git-crypt` for encrypted secrets. To unlock:
```bash
pbpaste | base64 --decode > ./secret-key
git-crypt unlock ./secret-key
```

Reference: https://lgug2z.com/articles/handling-secrets-in-nixos-an-overview/

### Neovim Configuration

The Neovim configuration is split between two files:
- `home-manager/server/neovim/default.nix` - Package definitions and plugin list
- `home-manager/server/neovim/init.lua` - Neovim configuration (loaded directly via `:luafile`)

**IMPORTANT**: When editing `init.lua`, you do NOT need to run `just deploy`. The file is loaded directly by Neovim at startup (see `extraConfig` in `default.nix`), so changes take effect immediately when you restart Neovim. Only run `just deploy` when modifying `default.nix` (packages, plugins, etc.).

### Manual Setup Steps

After initial deployment:
1. Run `Hyprland` to start the desktop environment
2. Install Doom Emacs (see `home-manager/server/emacs/default.nix`):
   ```bash
   git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
   ~/.config/emacs/bin/doom install
   ~/.config/emacs/bin/doom sync
   ```

## Important Files

- `flake.nix` - Flake configuration with inputs and system definition
- `configuration.nix` - System-wide configuration (network, users, hardware, fonts)
- `machines/{framework,dellxps}/configuration.nix` - Machine-specific settings
- `home-manager/default.nix` - User configuration entry point
- `home-manager/server/core.nix` - Core CLI tools and shell configuration
- `Justfile` - Build and maintenance commands

## Conventions

- Allow unfree packages globally (`nixpkgs.config.allowUnfree = true`)
- Use flakes and nix-command experimental features
- Automatic garbage collection runs weekly
- Auto-optimize nix store is enabled
- Default shell: Fish (enabled system-wide)
- Default editor: Set via `$EDITOR` environment variable
- Git default branch: `main`
- Version control: Both `git` and `jujutsu` (jj) are configured
