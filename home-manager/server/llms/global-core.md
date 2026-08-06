# Agents.md (global / user-level) — core

This is the computer-wide memory file: the always-on rules and prohibitions, rendered to **both**
`~/.claude/CLAUDE.md` and `~/.pi/agent/AGENTS.md` (home-manager, `default.nix`, plus the optional
`pellucid` prose when that toggle is on). The long-running beads/jj **procedures** are NOT here —
they live once as lazily-loaded **skills** in the soroban package, read by pi directly and by
Claude Code via the `~/.claude/skills` symlinks. It applies to **every** project on this machine.
Project-level `CLAUDE.md` files supplement and may override anything here.

**Per-harness note:** where a rule below names a pi command or the soroban extension, that
behaviour is **pi-only**. Under Claude Code (or any other harness) do the equivalent by hand; the
automatic mechanism does not exist there.

---

## Work on this machine (NixOS — imperative ops are always wrong)

This machine is NixOS: **everything that persists is declared in `/etc/nixos` and rebuilt.**
**Never mutate the running system imperatively** (applies to both Claude Code and pi):

- Package manager is **`nix`, NOT apt/brew/pip/cargo/npm**. Install via `nixpkgs`, a project
  devShell, or home-manager `home.packages` — never a bare `pip install`/`cargo install`/`npm -g`.
  (Language pkg-managers in a devShell manage *language* deps only.)
- **No `sudo`, not root.** Hardware/env/scripts go through NixOS options / home-manager, never a
  downloaded installer or a PPA. The user rebuilds.
- **Never hardcode a `/nix/store` hash** (it changes between rebuilds). Reference this repo by the
  absolute path `/etc/nixos/…`.

The full detail (what's guaranteed true/false, what to do instead) is in the **`nixos-machine`
skill** — read it before changing system or hardware config, or when a command is "not found".

---

## Model Delegation (conserve Opus/Fable allowance)

For all coding tasks, use your judgement to decide an appropriate lower-power model and run
that work in a subagent. The aim is to keep the main thread on Opus/Fable but not waste that
allowance on work a cheaper model can handle — delegate the mechanical, well-scoped, or
easily-verified parts to a subagent with a lower-power model, and reserve Opus/Fable for the
planning, judgement, and review that genuinely need it.

**Subagent mode:** Always run subagents in `/caveman:caveman ultra` mode unless instructed otherwise.
This reduces token usage on delegate work while maintaining full technical accuracy.

---

## Docs-first for unfamiliar tools

Before using an unfamiliar CLI or library, read its actual interface rather than
guessing — run `<tool> --help` (or `<tool> <subcommand> --help`), or read the
project's docs/README. Modern context windows absorb a lot up front, and a wrong
guess about flags or API shape is more expensive than the read. Especially cheap
and worthwhile when delegating to a lower-power subagent.

---

## Hoard reusable examples

Figure a trick out once, then keep a minimal working example so it never has to be
re-derived. The hoard lives at **`/etc/nixos/home-manager/server/llms/examples/`** —
in the version-controlled NixOS config repo, so it syncs across all machines. Do
NOT use `~/.claude/examples/` (machine-local, doesn't travel).

- Before solving a known-shaped problem, search it first:
  `rg -l <keyword> /etc/nixos/home-manager/server/llms/examples`. Building something
  new by combining existing working examples beats starting cold.
- After cracking something reusable (a gnarly command, config pattern, API dance,
  effective prompt), add it. The `README.md` in that directory documents the exact
  format and the one-line index to append to.

---

## Development Environment (NixOS + flake devShells)

Every project pins its toolchain in a `flake.nix` `devShells.default`, entered automatically by
`direnv` (`.envrc` = `use flake`). Inside a project dir the toolchain is already on `PATH` — do
NOT `nix-shell`/`nix develop` manually, and prefer the project's `Justfile` recipes. If a command
is "not found", add it to the flake's devShell and re-enter — never install globally. Add a system
tool/lib → edit the flake; add a language library → use that stack's package manager (opam / cargo
/ pixi, project-local, activated by the devShell). The per-language detail (OCaml/Rust/Python
shapes) is in the **`nixos-machine` skill**.

---

## pi coding agent (NixOS-managed — config MUST live in /etc/nixos)

pi (`pi.dev`) is installed declaratively via the `pi` flake and its Home Manager module, NOT
`npm -g`/`curl | sh`. All pi config lives under `/etc/nixos/home-manager/server/llms/` (`pi.nix`
= declarative harness config, models, and generated theme). **Edit the source in
`/etc/nixos` and rebuild — never hand-edit `~/.pi/agent/`** (resources are read-only store
symlinks; `settings.json` is merged by the flake wrapper so managed keys reset when pi starts;
`auth.json`/`sessions/`
are machine-local). Apply with `just deploy`; jj-track new files first (`jj status` snapshots).

---

## Version Control (jj — NEVER use git)

**NEVER run `jj git push` (or any push) — the user always pushes themselves.**
Prepare commits, then stop and let the user push.

**Do NOT create bookmarks by default.** Never add a bookmark to a commit as a matter of routine (e.g. one per issue during a hack or slip). Only run `jj bookmark create` when the user explicitly asks for a bookmark or asks you to open a PR (see PR workflow below).

**NEVER run `git` commands, not even read-only ones** (`git log`, `git show`, `git status`, `git diff`). Always use the jj equivalents (`jj log`, `jj show`, `jj status`, `jj diff`, `jj file show`). This applies in sibling repos too.

```bash
jj status / jj diff / jj log / jj show
jj commit -m "message" / jj describe -m "message"
jj new / jj new main / jj edit <commit> / jj abandon
jj squash / jj split / jj restore <file>
jj git fetch / jj rebase -d main
```

**`jj squash` can hang waiting on an interactive editor** if both the commit being squashed from and the commit being squashed to already have descriptions — jj opens an editor to combine them. Always pass `-m "<message>"` explicitly to `jj squash` to avoid this (or `--use-destination-message` to keep the destination's existing message unchanged).

**Always end with an empty `@`:** Every process that touches jj must finish with `@` being an empty, unnamed commit on top, e.g.:

```
@  wvsrrrur lachie@ohrg.org  (empty) (no description set)
○  wpktlots lachie@ohrg.org  Rewrites hover border system to use .row-card wrapper
○  tvuwulzs lachie@ohrg.org  Removes dead ColumnarDisplay and TabularDisplay components
◆  ntxzmrum lachie@ohrg.org  main  Introduces .row-card wrapper in VirtualizedTableRow
```

**PR workflow (only when the user asks for a PR/bookmark):**
```bash
jj bookmark create feat/<kebab-case-title> -r @-
# user pushes (e.g. `jj git push --allow-new`)
gh pr create --base main --head feat/<name> --title "..." --body "- bullet\n- bullet"
```

**Commit messages:** Present tense, user-focused. "Displays X in Y", not "Added X" or "Add X".

**NEVER list Claude as a co-author.** Do not add `Co-Authored-By: Claude` (or any Claude/Anthropic attribution) to commit messages or PR bodies. Commits are authored solely by the user.

**PR body:** 3-5 concise bullets. No "This PR", no LLM-style verbosity.

---

## Issue Tracking (beads/br — NEVER use markdown TODOs)

```bash
br ready --json                              # find unblocked work
br list --status=open
br show <id>
br create "Title" -t bug|feature|task -p 0-4 --json
br update <id> --status in_progress --json
br close <id1> <id2> --reason "Done" --json
br dep add <issue> <depends-on>
```

**Priorities:** 0=critical, 1=high, 2=medium, 3=low, 4=backlog. **Bead names** stay short — the id
carries identity, the name is shorthand (`rwq`, not `airborne-splash-rwq`).

The **workflows** (per-task sequence, hack, slip, workspaces, plan mode) and **how to write a
bead** are lazily-loaded skills (`soroban-workflow`, `soroban-hack`, `soroban-slip`, `jj-workspaces`,
`beads-plan-mode`, `bead-quality`) available to both harnesses — read the relevant one; this file
carries only the always-on rules below.

**Nothing under `.beads/` is committed.** `br` owns the whole directory — the db, its lock files,
and `issues.jsonl` (br's own full export, rewritten wholesale on every mutation) are all
machine-local. Soroban does NOT maintain a derived `open.jsonl` slice or any other tracked
export: a `br` mutation produces nothing to commit, so never look for a beads file in `jj status`
after one.

Each repo's `.gitignore` needs one line:

```gitignore
/.beads/
```

Bead state therefore does not travel between machines or agents through the repo — it lives only
in the local db. Treat `br` as a per-checkout tool, not a shared record.

**Two `br` writers on one repo can erase each other's newly-created beads** (`br` reimports from
`issues.jsonl`, and a jj workspace shares the repo-root db rather than getting its own). Under pi,
a session serializes its own `br` calls via the soroban lock; other callers and other harnesses
do not. So run **one writer at a time**, and after creating beads verify them with `br list`
rather than assuming they stuck.

**Labels reject `/`:** `br create -l <label>` allows only alphanumeric, hyphen, underscore, colon. The `feat/<kebab>` / `fix/<kebab>` convention (used for jj bookmarks / branches) CANNOT be a bead label verbatim — the slash fails validation (`invalid characters`). Use the hyphen form for the bead label (e.g. `feat-auto-label`, `chore-doc-test-sync`) while keeping the slash form for the bookmark/branch.

**Reimport reverts mutations:** `br` can silently undo a `close` / `--status in_progress` / `delete` because it reimports from `.beads/issues.jsonl`, which still holds the old state. Always re-check with `br list --status=open` (or `br show`) right after mutating, and re-issue if it reverted. For deletes, use `br delete <ids> --force --hard` so the JSONL tombstone is hard-pruned and reimport can't resurrect the issue.
