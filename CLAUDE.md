# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Note**: This project uses [bd (beads)](https://github.com/steveyegge/beads) for issue tracking. Use `bd` commands instead of markdown TODOs. See AGENTS.md for workflow details.

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

## Issue Tracking with Beads

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Auto-syncs to JSONL for version control
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**
```bash
bd ready --json
```

**Create new issues:**
```bash
bd create "Issue title" -t bug|feature|task -p 0-4 --json
bd create "Issue title" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**
```bash
bd update bd-42 --status in_progress --json
bd update bd-42 --priority 1 --json
```

**Complete work:**
```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task**: `bd update <id> --status in_progress`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`

### Auto-Sync

bd automatically syncs with git:
- Exports to `.beads/issues.jsonl` after changes (5s debounce)
- Imports from JSONL when newer (e.g., after `git pull`)
- No manual export/import needed!

### MCP Server (Recommended)

If using Claude or MCP-compatible clients, install the beads MCP server:

```bash
pip install beads-mcp
```

Add to MCP config (e.g., `~/.config/claude/config.json`):
```json
{
  "beads": {
    "command": "beads-mcp",
    "args": []
  }
}
```

Then use `mcp__beads__*` functions instead of CLI commands.

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems

---

## The bd/jj workflow 

**IMPORTANT**: ALWAYS use the jj squash workflow when working on bd tasks, even if you're only implementing a single task. This workflow should be your default approach.

When working through bd (beads) tasks, use the jj squash workflow. This creates a clean commit history where related work is grouped together.

### The Squash Pattern

The workflow maintains two commits:
- **Named commit** (bottom): Empty at first, receives work via squash. Has a descriptive message.
- **Working commit** (top): Unnamed and empty. All changes happen here, then get squashed down.

After squashing, the working commit becomes empty again, and the pattern repeats.

### Per-Task Workflow

For each bd task, follow this sequence:

1. **Name the commit**: Run `jj describe -m "Present tense description"`
   - Message describes what the app does after this change
   - Completes the phrase: "when this commit is applied, the app..."
   - Examples:
     - "Renders timeline using real-world data"
     - "Improves coloration of navbar"
     - "Adds date-based scroll mapping to timeline"
   - Use present tense, NOT past tense or imperative mood
   - Focus on user-visible changes, not implementation details

2. **Create working commit**: Run `jj new`
   - This creates a new empty commit on top where you'll do the work
   - All file changes will go into this commit

3. **Complete the bd task**:
   - Implement the changes
   - Test that it works
   - Close the issue: `bd update <id> --status closed`

4. **Squash the work**: Run `jj squash`
   - Moves all changes from the working commit (top) into the named commit (below)
   - Working commit becomes empty again, ready for next task

5. **Repeat**: Go to step 1 for the next task

### Commit Message Examples

✅ Good (present tense, user-focused):
- "Displays flight hours in timeline visualization"
- "Renders year markers in timeline sidebar"
- "Synchronizes timeline scroll with table position"
- "Shows data gaps as empty bars in timeline"

❌ Bad (wrong tense or too technical):
- "Added TimelineBar component" (past tense)
- "Add timeline visualization" (imperative, not present)
- "Refactors VerticalTimeline.jsx to use new components" (implementation detail)
- "Created data utilities module" (past tense, not user-visible)

### When to Use This Workflow

**ALWAYS use this workflow** when working on bd tasks. This is the standard approach for this project.

The workflow works for:
- Single bd tasks (one task = one commit)
- Multiple related bd tasks (multiple tasks = one commit)
- Any feature or bug fix tracked in bd

Only skip this workflow when:
- User explicitly requests a different approach
- Working on unrelated changes that must be separate commits
