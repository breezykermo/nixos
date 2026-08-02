# Agents.md (global / user-level)

This is the computer-wide memory file. home-manager (`home-manager/server/llms/default.nix`)
concatenates it with the optional `pellucid` prose rules (`./pellucid.md`, appended when the
`pellucid` toggle in that module is true) and writes the result to both `~/.claude/CLAUDE.md`
**and** `~/.pi/agent/AGENTS.md`. It applies to **every** project on this machine. Project-level `CLAUDE.md` files supplement and may override anything here.

---

## Work on this machine (NixOS — imperative ops are always wrong)

This machine is NixOS. **Everything is defined declaratively in /etc/nixos and rebuilt.**
The live filesystem is a managed snapshot — you cannot expect the conventions of a normal Linux
install. The following apply to **both Claude Code and pi** equally: **never mutate the running
system imperatively**; always do configuration through /etc/nixos.

### What's guaranteed true (and false)
- **Package manager is `nix`, NOT apt/yum/dnf/brew/pip/cargo/npm.** There *may* be
  language-pkg-managers available inside project devShells (opam, cargo, pixi) but they
  manage *language deps*, not system software.
- **/etc/nixos is the only place you define anything that persists across reboots.**
  Anything else (manual file drops, config in /tmp, env vars set in a session)
  disappears on rebuild or login.
- **There is no `sudo`.** You are not root. NixOS does not use the traditional
  permission model — user config lives in ~/.config and home-manager manages everything.

### What to do instead
- **Software:** always install via `nixpkgs` (flake `packages.<system>.<name>`), project devShell,
  or home-manager `home.packages`. Build from source only as a last resort. The user will rebuild
  (via pi: `just deploy` from /etc/nixos; via Claude Code: commit and wait for the human to push +
  rebuild).
- **Hardware:** only configurable through NixOS `hardware.<something>.enable = true;`
  options or by adding packages to `home.packages`. Never "download and run" a binary
  installer or use a PPA.
- **Environment variables / scripts:** go in home-manager (`home.sessionVariables` or
  home activation scripts), not in shell rc files. If a tool needs a wrapper, add it as an
  `extraPackages` entry or write a small script in the project.
- **/etc/nixos is version-controlled** (jj). It's also available at project level when editing:
  it's just `.` if you're in that repo. Changes land via the processes documented below
  (pi) or after the human pushes + rebuilds (Claude Code).

### NixOS filesystem conventions to remember
- Packages live in `/nix/store/…`. Symlinked into the user profile at
  `/home/lox/.nix-profile/bin/<name>`. That home-directory path is itself a symlink.
  The store path may change between rebuilds — **never hardcode a /nix/store hash** in your code.
- If you need to reference a file relative to this config repo (e.g. reading docs), use
  the absolute path on disk: `/etc/nixos/…`. This is always available inside any directory.

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

This machine is **NixOS**. Every project pins its toolchain in a `flake.nix` exposing a
`devShells.default`, entered automatically via `direnv` (`.envrc` contains `use flake`). So
inside a project dir the toolchain (compilers, package managers, linters, test runners) is
already on `PATH` — do NOT `nix-shell`/`nix develop` manually and do NOT install tools
globally or with the system package manager. If a command is "not found", the fix is adding it
to the flake's `devShell` (`packages`/`buildInputs`), then re-entering the shell — never a bare
`pip install`/`cargo install`/`npm -g`.

- Prefer the project's `Justfile` recipes when present — they wrap the correct flags.
- Build/test/lint commands run from inside the devShell (direnv handles this on `cd`).
- Some flakes expose extra shells (e.g. `use flake .#cuda`); check `.envrc` comments and
  `flake.nix` `devShells` before assuming there's only one.

**Two-layer split (the general rule).** The flake provides the *system* layer — the language
runtime/compiler, its native package manager, C toolchain, and system libraries. The language's
*own* package manager then manages *language* deps, usually in a **project-local** dir activated
by the devShell `shellHook`. So: add a system tool/lib → edit the flake; add a language
library → use that stack's package manager (which the flake put on `PATH`). Typical shapes:

- **OCaml / OxCaml:** flake supplies `opam` + a C/C++ toolchain (for OxCaml, `clang` wrapped to
  force `-std=c++17`) + system libs (`gmp`, `openssl`, `libffi`, `zlib`). The `shellHook`
  bootstraps and activates a **project-local opam switch** (`OPAMROOT=$PWD/.opam-root`, switch at
  `$PWD`) so OCaml deps live in the repo, not globally. OxCaml's `+ox` compiler variant needs
  network at build time, so it can't build in a Nix sandbox — the flake's package output is a
  *runner* that execs `just setup && just build`, not a pure derivation. Build via the `Justfile`.
- **Rust:** flake pins the toolchain via `rust-overlay` reading `rust-toolchain.toml` (single
  source of truth) + native deps (`pkg-config`, `openssl`, `perl`). `cargo` manages crates from
  `Cargo.toml`/`Cargo.lock`. Reproducible builds use `crane` with a cached deps-only layer.
  In-shell you just run `cargo build`/`cargo test` (or `Justfile` recipes).
- **Python:** flake supplies `pixi` (often wrapped in `steam-run`, a light FHS, so conda/binary
  wheels find `glibc`/`stdenv.cc.cc.lib`/`zlib`) + optional variant shells (e.g. `.#cuda` sets
  `CUDA_PATH`/`LD_LIBRARY_PATH`). `pixi` manages Python deps from `pyproject.toml`/`pixi.lock`
  in a project-local `.pixi/` env — run all Python work through `pixi run ...`/`pixi install`,
  never ambient `python`/`pip`.

Live examples on this box (may not exist on every machine): `~/code/_karaji/karaji` (OxCaml),
`~/code/_rheo/rheo` (Rust), `~/code/_pragma/pragma` (Python).

---

## pi coding agent (NixOS-managed — config MUST live in /etc/nixos)

This machine's **pi** (`pi.dev`, binary `pi`) is installed declaratively via home-manager,
NOT via `npm install -g` or `curl | sh`. Everything about pi lives in the version-controlled
NixOS config repo under **`/etc/nixos/home-manager/server/llms/`**:

- **`pi.nix`** — builds the `pi` binary from the upstream release tarball (version + two hashes;
  the bump recipe is in the file's header comment). This is the ONLY place the pi version changes.
- **`pi-config.nix`** — the standalone config module (imported by `default.nix` via `imports`).
  All declarative pi config is defined here. `default.nix` itself only adds the binary to
  `home.packages` and the `imports` line.
- **`pi/`** — the read-only resource tree, sourced by `pi-config.nix`: `prompts/`, `skills/`,
  `extensions/`, `themes/` (each seeded with `.gitkeep`). Add a prompt/skill/extension/theme by
  dropping it in the matching subdir. See `pi/README.md`.
- **`hooks/merge-pi-settings.sh`** — the jq-merge script for settings.json (below).

**To edit pi config so it persists, change the source in `/etc/nixos` and rebuild — never
hand-edit `~/.pi/agent/`.** Two distinct mechanisms, by how pi treats each path:

- **Read-only resources** (`extensions`/`skills`/`prompts`/`themes`): `home.file` symlinks from
  `./pi/<dir>` into the nix store (same pattern as the pinned Claude skills). `~/.pi/agent/<dir>`
  is a read-only store symlink — editing it directly fails or is wiped on rebuild.
- **`settings.json`** (read-WRITE — pi persists `/settings`, `/model`, theme, changelog dismissal):
  NOT symlinked. Managed defaults live in the `piSettings` attrset in `pi-config.nix` and are
  jq-merged into the mutable file on activation (mirrors the `claudeGitHook` precedent). Managed
  keys WIN, so an interactive `/settings` change to a managed key is reset to the nix value on the
  next rebuild — edit `piSettings` to change a default. pi's runtime-only keys are preserved.
- **NOT managed** (secrets/runtime state, stays machine-local): `auth.json`, `models-store.json`,
  `sessions/`.

Apply changes with `just deploy` from `/etc/nixos` (never by touching `~/.pi/agent/` or the nix
store). New files must be jj-tracked before the flake sees them — `jj status` snapshots the
working copy.

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

**Priorities:** 0=critical, 1=high, 2=medium, 3=low, 4=backlog

**Bead names:** Keep them as short and simple as possible. Prefer concise 3-4 character identifiers over descriptive hyphenated names. For example, `rwq` is much better than `airborne-splash-rwq`. The bead ID carries the identity; the name is just a local shorthand.

**Partly committed — `brsave` before every squash.** Nearly all of `.beads/` is per-machine
working state (the sqlite db, its locks, `.br_history/`, and `issues.jsonl` — br's own full
export, rewritten wholesale on each mutation and carrying every closed bead). Exactly one file
is shared: **`.beads/open.jsonl`**, holding the `open` and `in_progress` beads and nothing else,
so live work travels with the repo while closed beads and the db stay local.

```bash
brsave            # refresh .beads/open.jsonl — run before every `jj squash`
brsave --check    # exit 1 if the export is out of date, write nothing
brsave --import   # seed a local db from the export (fresh clone, no .beads/ db yet)
```

`brsave` is installed computer-wide (home-manager, `home-manager/server/llms/scripts/brsave.sh`
in /etc/nixos) and resolves the repo root itself, so it works from any subdirectory of any repo
— there is nothing to copy into a new project. It runs `br sync --flush-only --force` first, so
`br sync` is expected here rather than forbidden. Do NOT run a bare `br sync` yourself.

Each repo's `.gitignore` needs these three lines, **in this order** (a negation cannot re-enter
a directory excluded as a directory, and `~/.config/git/ignore` on this machine carries a
`**/.beads/` rule from an old `bd init --stealth` that a repo `.gitignore` has to outrank):

```gitignore
!/.beads/
/.beads/*
!/.beads/open.jsonl
```

Remove any blanket `.beads/` line when adding them. `brsave` warns when they are missing; it
never edits `.gitignore` itself.

**A conflict in `.beads/open.jsonl` is ALWAYS resolved by union — never by picking a side.**
The file is one bead per line, and two sides that touched it were, almost always, filing
*different* beads. Taking either side silently deletes the other's work, and because the
losing beads were never anywhere else, there is nothing to notice afterwards.

The rule:

1. **Never `jj restore` / checkout one side of this file.** Not as a shortcut, not "to unblock
   the rebase". The whole point of the file is that it is additive.
2. Take the side with the **closes** as the base — a bead absent from an export was closed, and
   re-adding it silently reopens finished work. Then add the beads the other side introduced.
   Match on the `id` field; ids are unique, so a union keyed on id is well-defined.
3. Verify all three properties before committing, because each is a distinct way to get it
   wrong: every id from both sides is present, no closed bead came back, and the count equals
   what you expect.
4. Resolve at the **db** level, not just the file: whichever db you then `brsave` from must know
   about both sides, or the very next export undoes the merge. `brsave --import` on the unioned
   file first, then `brsave`, is the safe order.

Note that `git`'s `merge=union` driver in `.gitattributes` would do exactly this automatically,
but jj does not honour gitattributes merge drivers, so this stays a manual rule.

**What causes these conflicts (and the loss that comes with them):** two `br` writers against
one repo. `br` resolves its db from the *repo root*, so a **jj workspace shares the main
checkout's `.beads/` db** — a sibling workspace dir does NOT get its own, whatever the
workspace-isolation section might suggest. Two agents therefore mutate one sqlite db while
exporting into two different checkouts' `open.jsonl`.

Worse than the file conflict: `br` reimports from `.beads/issues.jsonl` on some operations, so
one session's mutation can **silently erase beads another session just created** — not
conflict, erase. Observed 2026-08-02: seven freshly created beads vanished from every db and
every export, recoverable only because the `br create` invocations were still in the agent's
scrollback. So:

- Treat "I created beads and another session was running" as a claim to VERIFY, not to assume:
  `br list -l <label>` immediately after, and again after any `brsave`.
- Keep the `br create` text recoverable (a file, or the transcript) until it is committed.
- One writer at a time. This is the single-writer protocol below, and the reason for it is loss,
  not merely double-claims.

**Labels reject `/`:** `br create -l <label>` allows only alphanumeric, hyphen, underscore, colon. The `feat/<kebab>` / `fix/<kebab>` convention (used for jj bookmarks / branches) CANNOT be a bead label verbatim — the slash fails validation (`invalid characters`). Use the hyphen form for the bead label (e.g. `feat-auto-label`, `chore-doc-test-sync`) while keeping the slash form for the bookmark/branch.

**Reimport reverts mutations:** `br` can silently undo a `close` / `--status in_progress` / `delete` because it reimports from `.beads/issues.jsonl`, which still holds the old state. Always re-check with `br list --status=open` (or `br show`) right after mutating, and re-issue if it reverted. For deletes, use `br delete <ids> --force --hard` so the JSONL tombstone is hard-pruned and reimport can't resurrect the issue.

---

## The br/jj Workflow (ALWAYS use for br tasks)

**Session prerequisite** — verify jj identity:
```bash
jj config list --user
# If missing:
jj config set --user user.name "Lachlan Kermode"
jj config set --user user.email "lachie@ohrg.org"
```

**Always end with an empty `@`:** After every jj workflow, `@` must be an empty unnamed commit on top.

**Ordering around `br close`:** `.beads/open.jsonl` is tracked, so beads state DOES ride in jj commits — but only the open/in-progress slice, which `brsave` derives. Close the issue first, then `brsave`, then squash: the close drops the bead out of the export, so the same commit that finishes the work also removes it from the shared list. Everything else under `.beads/` is ignored and never committed.

**Per-task sequence:**
1. `br update <id> --status in_progress`
2. `jj log` — if empty unnamed commit below working commit, name it: `jj describe -m "..."`
3. `jj new` — fresh working commit
4. Do the work, run tests
5. `br close <id> --reason "Done"` — records the issue as done
6. `brsave` — refresh `.beads/open.jsonl` so the closed bead leaves the shared export. ALWAYS before the squash; the export is a tracked file and belongs in the same commit as the work.
7. `jj squash --use-destination-message` then `jj describe -r @- -m "Present tense description"` — using `--use-destination-message` avoids the interactive editor that pops up when both commits already have descriptions
8. `jj log` — verify history shows correct author on each commit; `@` must be empty and unnamed

---

## Workspace isolation (ALWAYS for br/jj hack & slip)

Hack and slip sessions are long-running and may run **concurrently with other agents** on the
same repo. Two agents sharing one checkout fight over the single `@` working-copy commit and
stomp each other's uncommitted changes. So **while actively implementing a bead, do every step
inside a dedicated jj workspace.** A workspace is an independent working copy on disk that shares
the same underlying repo — commits, operation log, and history — with the main checkout, so all
committed work still lands in the one repo; only the working copies are isolated.
Ref: https://www.joshualyman.com/2026/02/demystifying-jujutsu-jj-workspaces/

**A workspace lives exactly as long as the implementation does.** Create it when you start a
bead; fold it back into the main checkout the moment that bead's work is committed, BEFORE
pausing to prompt the user. A workspace must never be sitting around while you wait on a human —
if the next thing you do is ask a question, the workspace should already be gone. Further work
means a NEW workspace. A hack, which never pauses, may keep one workspace for its whole loop;
a slip creates and folds one per bead.

**Set up (at the start of each bead):**
```bash
# Run from inside the repo. <tag> = a short, unique session id (vary it per agent/bead).
jj workspace add --name <tag> -r @- ../<repo>-<tag>     # sibling dir; branch off the latest work, NOT stale main
cd ../<repo>-<tag>
direnv allow                                            # new dir has the tracked .envrc but isn't allowed yet
brsave --import                                         # tracked open.jsonl came with the checkout; the db did not
```
Branch the workspace off the tip of the work so far (`@-` in the main checkout, i.e. the last
named commit), not off `main`. Branching off `main` every time produces parallel chains that
have to be rebased together later.
Skip the `brsave --import` in a multi-agent session — there the orchestrator owns beads entirely
(see the single-writer protocol below).
- The workspace dir MUST be a **sibling** of the repo (`../<repo>-<tag>`), never nested inside it.
- **beads coordination (prevent double-claims AND loss):** `br` resolves its db from the **repo
  root**, not the current directory — and a jj workspace's repo root is the SHARED repo. Measured
  2026-08-02: a `../<repo>-<tag>` workspace never grew a `.beads/` directory at all; `brsave
  --import`, every `br create`, and a later `brsave` all read and wrote the MAIN checkout's db
  and the MAIN checkout's `open.jsonl`. So a workspace does **not** give an agent its own beads
  db, and cannot be used to isolate one.
  That makes the failure worse than double-claiming. N agents in N workspaces share ONE mutable
  sqlite+jsonl, which is exactly the "reimport reverts mutations" race above — and it does not
  merely revert a status, it can **delete beads one agent created while another was writing**.
  `br update --status in_progress` is therefore not a reliable claim either: two agents can both
  `br ready` and pick the SAME top issue → two commits for one bead.
  - **Protocol (single-writer):** the orchestrator (or you, before spawning agents) runs
    `br ready` **once**, partitions the ready issues into **disjoint** per-agent sets, and hands
    each agent the **explicit issue IDs** to work. Agents do NOT self-select from a shared
    `br ready`. One writer owns `.beads/` and applies every `br` mutation (claim/close); the
    other agents just report results back to it. This is the only reliable guard against two
    agents solving the same bead. The single writer also owns `brsave`: an agent whose workspace
    has no db (or a stale imported one) would export a wrong `open.jsonl` and conflict with the
    others, so in a multi-agent session only the writer refreshes the export. A solo workspace
    session is the normal case and runs `brsave` itself, per the per-task sequence.
- The empty-`@` rule and the full br/jj per-task sequence apply unchanged — just inside this workspace.
- **Toolchain re-bootstrap:** project-local language envs are gitignored (e.g. `.opam-root/`,
  `.pixi/`, opam switch dirs, Rust `target/`), so a fresh workspace does NOT inherit them — the
  first `direnv allow` there re-runs the flake `shellHook` and rebuilds the whole toolchain
  (slow, duplicate disk). To avoid it, symlink the project-local env dir(s) from the main
  checkout into the new workspace. Trade-off: shared build state can race across concurrent
  agents for some stacks, so symlink only read-heavy caches, not active build/output dirs.

**Fold back into main (as soon as the bead's work is committed):**
```bash
cd <main repo>                     # back to the primary working copy
jj workspace forget <tag>          # drops the workspace ref; its empty @ is abandoned
rm -rf ../<repo>-<tag>             # remove the directory
jj rebase -s <main @> -d <tip>     # restack the main working copy ON TOP of the new commits
jj status                          # @ must now be empty again
```
`jj log` from the main checkout already shows every commit the workspace created — they live in
the shared repo. But **`jj workspace forget` alone does not fold the work in**: the main
checkout's `@` is still parked wherever it was when the workspace was created, so the new commits
sit off to one side and the next bead branches off stale history. The `jj rebase -s <main @> -d
<tip>` is the fold — without it you accumulate parallel chains and end up rebasing by hand later.
`<tip>` is the last named commit the workspace produced; `<main @>` is the main checkout's
working-copy change id. After the rebase `@` should report `(empty)` — if it does not, inspect
`jj diff` before continuing (a stray file, e.g. `.claude/settings.local.json`, may have been
snapshotted into it).

**Concurrent commits are safe:** multiple workspaces committing into the one shared repo use jj's optimistic operation log. Under concurrency jj may print `concurrent modification` but auto-reconciles — inspect with `jj op log` if curious; no manual action is normally needed. Don't panic at the warning.

---

## br/jj Hack (only when user says "hack" or "br/jj hack")

*Hacking is the period when a young hawk is flown free and unsupervised, returning at will — here,
the ready queue worked straight through with no review pauses.* `churn` is still an accepted alias.

**ALWAYS run in `/caveman:caveman ultra` mode** for the entire hack — invoke it before the
first loop iteration and stay in it throughout.

**Before first loop iteration** — verify jj identity (commits without author are broken):
```bash
jj config list --user
# Must show user.name and user.email. If missing:
jj config set --user user.name "Lachlan Kermode"
jj config set --user user.email "lachie@ohrg.org"
```

**Then set up an isolated jj workspace** and run the ENTIRE hack inside it — see
*Workspace isolation* above. Never run a hack in the shared main checkout.

Loop until no open issues:
1. `br ready --json` — pick highest priority (bugs/tasks/features, not epics/chores)
2. Implement with br/jj workflow
3. `/clear` — clear context
4. Repeat

When done, run the project's formatter and linter (see the project's `CLAUDE.md` for exact
commands) and `brsave`, then `jj squash --use-destination-message` if that produced changes.
Leave `@` empty. Then fold the workspace back into main (`jj workspace forget` + `rm -rf` +
`jj rebase`, see *Workspace isolation*).

Report: list all closed issues.

---

## br/jj Slip (only when user says "slip" or "br/jj slip")

*A slip is a single flight loosed at one quarry — here, one bead at a time, with a review pause
between each.* `pair` is still accepted as an alias.

The trigger `slip on <X>` is equivalent to `br/jj slip on <X>` — bare `slip` and `br/jj slip`
mean the same thing; run this same workflow either way.

**ALWAYS run in `/caveman:caveman ultra` mode** for the entire slip — invoke it before
the first loop iteration and stay in it throughout.

**Before first loop iteration** — verify jj identity (commits without author are broken):
```bash
jj config list --user
# Must show user.name and user.email. If missing:
jj config set --user user.name "Lachlan Kermode"
jj config set --user user.email "lachie@ohrg.org"
```

**Each bead gets its own jj workspace**, created when you start implementing it and folded back
into the main checkout before you pause for review — see *Workspace isolation* above. Never run a
slip in the shared main checkout, and never leave a workspace standing while waiting on the user.

Loop until no open issues or user stops:
1. `br ready --json` — pick highest priority (bugs/tasks/features, not epics/chores)
2. **Create the workspace for this bead** (`jj workspace add --name <tag> -r @- ../<repo>-<tag>`,
   see *Workspace isolation*), then implement with the br/jj workflow inside it, but **do NOT
   close the issue** — it stays `in_progress`. Do the work, run tests, run `brsave` (the
   `in_progress` status belongs in the export), then **do the full squash so a named jj commit
   already exists**: `jj squash --use-destination-message` then
   `jj describe -r @- -m "Present tense description"`. The `br close` is the ONLY step deferred;
   everything else (squash into a named commit, empty `@` on top) is done before the pause.
3. **Fold the workspace back into main** — `jj workspace forget <tag>`, `rm -rf` the directory,
   and rebase the main checkout's `@` onto the new tip, per *Workspace isolation*. Do this
   BEFORE step 4: the user is about to review, and no workspace should exist while you wait.
4. **Pause and prompt the user for review** — present what was done, ask whether to continue.
   The named commit is already in place; the issue stays `in_progress` until the user confirms.
   - User may review code, request changes, add/modify/remove br issues
   - If user requests changes: that is more implementation, so **open a fresh workspace for it**
     (same `jj workspace add` as step 2) and fold it back again before pausing. Do NOT squash
     into the existing named commit — commit the edits as their own named commit on top, so each
     review round is its own commit. One bead can map to several jj commits this way; that's
     fine, the bead-to-commit relationship is one-to-many, not one-to-one.
   - Only when the user explicitly confirms (e.g. "continue", "next", "go"):
     close the issue (`br close`), then `brsave` — the commit for this bead is already named, so
     the refreshed export rides in the next commit (or in the end-of-session squash below) rather
     than getting its own — then move to the next issue
   - If user says "stop" or "done", exit the loop (leave the current issue `in_progress`)

When done — with no workspace open, in the main checkout — run the project's formatter and linter
(see the project's `CLAUDE.md` for exact commands) and `brsave`, then
`jj squash --use-destination-message` if that produced changes. Leave `@` empty.

Report: list all closed issues.

---

## Plan Mode (activated by "plan mode", "let's plan", "design this", or any prompt ending with "BEADS")

**Rules:** No code, no file edits (except `.beads/`). Output is beads issues only.

**Workflow:**
1. Understand goal, ask clarifying questions
2. Decompose into discrete br issues with type, priority, acceptance criteria
3. Present proposal to user, ask if they want to create the issues
4. If yes: run `br create` commands (parallel where possible), set up deps with `br dep add`
   - Each issue's `--description` must be **fully self-contained** — written for a less capable agent with zero prior context. Do all research and code dives during planning; embed the findings directly in the description. Include: background/motivation, every relevant file path and line number, exact step-by-step instructions, and the precise expected outcome. The implementer must not need to investigate, infer, or look anything up.
   - Issues must also be **human-readable**: during a slip the user reads each issue to verify agents are working correctly, so write in clear prose, not cryptic shorthand.
5. `brsave` — the new issues are shared work, so put them in `.beads/open.jsonl`. Then commit
   just the export: `jj describe -m "Files <n> beads for <topic>"` and `jj new`. This is the one
   file edit plan mode makes.
6. List created IDs and stop — do NOT implement, do NOT ask if user wants to implement

**Exits** when user says "hack", "slip", "start implementing", or "go".
