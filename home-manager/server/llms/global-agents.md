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

**Do NOT create bookmarks by default.** Never add a bookmark to a commit as a matter of routine (e.g. one per issue during churn/pair). Only run `jj bookmark create` when the user explicitly asks for a bookmark or asks you to open a PR (see PR workflow below).

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

**Local-only:** `.beads/` is gitignored, never commit it, never run `br sync`.

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

**Always end with an empty `@`:** After every jj workflow, `@` must be an empty unnamed commit on top. `.beads/` is gitignored (see `.gitignore`), so `br close` never modifies a tracked file and never rides in a jj commit — its ordering relative to `jj squash` is immaterial for version control. Close whenever is convenient; nothing beads-related is ever committed.

**Per-task sequence:**
1. `br update <id> --status in_progress`
2. `jj log` — if empty unnamed commit below working commit, name it: `jj describe -m "..."`
3. `jj new` — fresh working commit
4. Do the work, run tests
5. `br close <id> --reason "Done"` — records the issue as done. `.beads/` is gitignored, so this changes no tracked file; there is nothing beads-related to squash into any commit.
6. `jj squash --use-destination-message` then `jj describe -r @- -m "Present tense description"` — using `--use-destination-message` avoids the interactive editor that pops up when both commits already have descriptions
7. `jj log` — verify history shows correct author on each commit; `@` must be empty and unnamed

---

## Workspace isolation (ALWAYS for br/jj churn & pair)

Churn and pair sessions are long-running and may run **concurrently with other agents** on the
same repo. Two agents sharing one checkout fight over the single `@` working-copy commit and
stomp each other's uncommitted changes. So **before starting any churn or pair loop, create a
dedicated jj workspace and do every step of the loop inside it.** A workspace is an independent
working copy on disk that shares the same underlying repo — commits, operation log, and history —
with the main checkout, so all committed work still lands in the one repo; only the working
copies are isolated.
Ref: https://www.joshualyman.com/2026/02/demystifying-jujutsu-jj-workspaces/

**Set up (once, before the loop):**
```bash
# Run from inside the repo. <tag> = a short, unique session id (vary it per agent).
jj workspace add --name <tag> -r main ../<repo>-<tag>   # sibling dir; working copy on top of main
cd ../<repo>-<tag>
direnv allow                                            # new dir has the tracked .envrc but isn't allowed yet
```
- The workspace dir MUST be a **sibling** of the repo (`../<repo>-<tag>`), never nested inside it.
- **beads coordination (prevent double-claims):** `br` reads `.beads/` from the current dir.
  If `.beads/` is **tracked** it's checked out into each workspace, but then every workspace has
  its OWN copy, so a claim/close in one is invisible to the others. If it's **gitignored** (the
  usual case — check `.gitignore`) a fresh workspace has no `.beads/` at all, so `br` starts
  empty there. Both naive fixes — run `br` from the main checkout, or symlink the main repo's
  `.beads/` into each workspace — make N agents share ONE mutable sqlite+jsonl, which exposes
  the "reimport reverts mutations" race above: `br update --status in_progress` is NOT a reliable
  claim, so two agents can both `br ready` and pick the SAME top issue → two commits for one bead.
  - **Protocol (single-writer):** the orchestrator (or you, before spawning agents) runs
    `br ready` **once**, partitions the ready issues into **disjoint** per-agent sets, and hands
    each agent the **explicit issue IDs** to work. Agents do NOT self-select from a shared
    `br ready`. One writer owns `.beads/` and applies every `br` mutation (claim/close); the
    other agents just report results back to it. This is the only reliable guard against two
    agents solving the same bead.
- The empty-`@` rule and the full br/jj per-task sequence apply unchanged — just inside this workspace.
- **Toolchain re-bootstrap:** project-local language envs are gitignored (e.g. `.opam-root/`,
  `.pixi/`, opam switch dirs, Rust `target/`), so a fresh workspace does NOT inherit them — the
  first `direnv allow` there re-runs the flake `shellHook` and rebuilds the whole toolchain
  (slow, duplicate disk). To avoid it, symlink the project-local env dir(s) from the main
  checkout into the new workspace. Trade-off: shared build state can race across concurrent
  agents for some stacks, so symlink only read-heavy caches, not active build/output dirs.

**Tear down (when the session ends):**
```bash
cd <main repo>            # back to the primary working copy
jj workspace forget <tag> # drops the workspace ref; its empty @ is abandoned
rm -rf ../<repo>-<tag>    # remove the directory
```
`jj log` from the main checkout still shows every commit the workspace created — they live in the shared repo.

**Concurrent commits are safe:** multiple workspaces committing into the one shared repo use jj's optimistic operation log. Under concurrency jj may print `concurrent modification` but auto-reconciles — inspect with `jj op log` if curious; no manual action is normally needed. Don't panic at the warning.

---

## br/jj Churn (only when user says "br/jj churn")

**ALWAYS run in `/caveman:caveman ultra` mode** for the entire churn — invoke it before the
first loop iteration and stay in it throughout.

**Before first loop iteration** — verify jj identity (commits without author are broken):
```bash
jj config list --user
# Must show user.name and user.email. If missing:
jj config set --user user.name "Lachlan Kermode"
jj config set --user user.email "lachie@ohrg.org"
```

**Then set up an isolated jj workspace** and run the ENTIRE churn inside it — see
*Workspace isolation* above. Never churn in the shared main checkout.

Loop until no open issues:
1. `br ready --json` — pick highest priority (bugs/tasks/features, not epics/chores)
2. Implement with br/jj workflow
3. `/clear` — clear context
4. Repeat

When done, run the project's formatter and linter (see the project's `CLAUDE.md` for exact
commands), then `jj squash --use-destination-message` if that produced changes. Leave `@` empty.
Then tear down the workspace (`jj workspace forget` + `rm -rf`, see *Workspace isolation*).

Report: list all closed issues.

---

## br/jj Pair (only when user says "br/jj pair" or "pair")

The trigger `pair on <X>` is equivalent to `br/jj pair on <X>` — bare `pair` and `br/jj pair`
mean the same thing; run this same workflow either way.

**ALWAYS run in `/caveman:caveman ultra` mode** for the entire pair session — invoke it before
the first loop iteration and stay in it throughout.

**Before first loop iteration** — verify jj identity (commits without author are broken):
```bash
jj config list --user
# Must show user.name and user.email. If missing:
jj config set --user user.name "Lachlan Kermode"
jj config set --user user.email "lachie@ohrg.org"
```

**Then set up an isolated jj workspace** and run the ENTIRE pair session inside it — see
*Workspace isolation* above. Never pair in the shared main checkout.

Loop until no open issues or user stops:
1. `br ready --json` — pick highest priority (bugs/tasks/features, not epics/chores)
2. Implement with br/jj workflow, but **do NOT close the issue** — it stays `in_progress`.
   Do the work, run tests, then **do the full squash so a named jj commit already exists**:
   `jj squash --use-destination-message` then `jj describe -r @- -m "Present tense description"`.
   The `br close` is the ONLY step deferred; everything else (squash into a named commit,
   empty `@` on top) is done before the pause.
3. **Pause and prompt the user for review** — present what was done, ask whether to continue.
   The named commit is already in place; the issue stays `in_progress` until the user confirms.
   - User may review code, request changes, add/modify/remove br issues
   - If user requests changes: do NOT squash into the existing named commit. The top commit
     (`@`) is already empty from the prior squash/pause — apply the requested edits directly
     into it, do NOT run `jj new` first (that would strand a second empty commit). Once edits
     are done, name it: `jj describe -m "Present tense description"`. THEN run `jj new` once to
     open the next empty commit, and pause for review again (still `in_progress`). This keeps
     each review round its own commit, and exactly one empty commit ever sits on top. One bead
     can map to several jj commits this way — that's fine, the bead-to-commit relationship is
     one-to-many, not one-to-one.
   - Only when the user explicitly confirms (e.g. "continue", "next", "go"):
     close the issue (`br close`) — `.beads/` is gitignored so this touches no tracked file and
     needs no squash — then move to the next issue
   - If user says "stop" or "done", exit the loop (leave the current issue `in_progress`)

When done, run the project's formatter and linter (see the project's `CLAUDE.md` for exact
commands), then `jj squash --use-destination-message` if that produced changes. Leave `@` empty.
Then tear down the workspace (`jj workspace forget` + `rm -rf`, see *Workspace isolation*).

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
   - Issues must also be **human-readable**: during `br/jj pair` the user reads each issue to verify agents are working correctly, so write in clear prose, not cryptic shorthand.
5. List created IDs and stop — do NOT implement, do NOT ask if user wants to implement

**Exits** when user says "br/jj churn", "br/jj pair", "start implementing", or "go".
