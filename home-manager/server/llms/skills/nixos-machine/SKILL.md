---
name: nixos-machine
description: How this NixOS machine works and why imperative operations are always wrong here — everything is declarative in /etc/nixos and rebuilt, there is no sudo and no ambient apt/brew/pip/cargo/npm, and project toolchains come from flake devShells entered by direnv. Use whenever you are about to install software, change system or hardware configuration, set environment variables, or a command is "not found" — before reaching for any imperative install. Not needed for ordinary in-project code edits.
---

# This machine (NixOS — imperative ops are always wrong)

Everything that persists is defined declaratively in **/etc/nixos** and rebuilt.
The live filesystem is a managed snapshot; normal-Linux install conventions do not
apply.

## Guaranteed true (and false)

- **Package manager is `nix`, NOT apt/yum/dnf/brew/pip/cargo/npm.** Language
  package managers (opam, cargo, pixi) may exist inside project devShells — they
  manage *language* deps, not system software.
- **/etc/nixos is the only place anything persists across reboots.** Manual file
  drops, `/tmp` config, session env vars — all gone on rebuild or login.
- **There is no `sudo`.** You are not root. User config lives in `~/.config` and
  home-manager manages it.

## What to do instead

- **Software:** install via `nixpkgs`, a project devShell, or home-manager
  `home.packages`. Build from source only as a last resort. The user rebuilds.
- **Hardware:** only via NixOS `hardware.<x>.enable = true;` options or packages.
  Never "download and run" an installer or add a PPA.
- **Env vars / scripts:** home-manager (`home.sessionVariables` / activation
  scripts), not shell rc files.

## Development environment

Every project pins its toolchain in a `flake.nix` exposing `devShells.default`,
entered automatically by `direnv` (`.envrc` has `use flake`). Inside a project dir
the toolchain is already on `PATH` — do NOT `nix-shell`/`nix develop` manually,
and do NOT install tools globally. If a command is "not found", the fix is adding
it to the flake's devShell and re-entering the shell — never a bare `pip
install`/`cargo install`/`npm -g`.

Two-layer split: the **flake** provides the system layer (language runtime/
compiler, its native package manager, C toolchain, system libs); the language's
**own** package manager then manages language deps, usually in a project-local dir
activated by the devShell `shellHook`. Add a system tool/lib → edit the flake; add
a language library → use that stack's package manager. Prefer the project's
`Justfile` recipes when present.
