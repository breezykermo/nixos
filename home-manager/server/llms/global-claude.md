# CLAUDE.md (global / user-level)

This is the computer-wide memory file, symlinked to `~/.claude/CLAUDE.md` by home-manager
(`home-manager/server/llms/default.nix`). It applies to **every** project on this machine.
Project-level `CLAUDE.md` files supplement and may override anything here.

---

## Version Control (jj — NEVER use git)

**NEVER run `jj git push` (or any push) — the user always pushes themselves.**
Prepare commits and bookmarks, then stop and let the user push.

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

**PR workflow:**
```bash
jj bookmark create feat/<kebab-case-title> -r @-
# user pushes (e.g. `jj git push --allow-new`)
gh pr create --base main --head feat/<name> --title "..." --body "- bullet\n- bullet"
```

**Commit messages:** Present tense, user-focused. "Displays X in Y", not "Added X" or "Add X".

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

---

## The br/jj Workflow (ALWAYS use for br tasks)

**Session prerequisite** — verify jj identity:
```bash
jj config list --user
# If missing:
jj config set --user user.name "Lachlan Kermode"
jj config set --user user.email "lachie@ohrg.org"
```

**Always end with an empty `@`:** After every jj workflow, `@` must be an empty unnamed commit on top. `br close` modifies `.beads/issues.jsonl`, so always close the issue **before** `jj squash` — that way the metadata change is included in the commit rather than left dangling in `@`.

**Per-task sequence:**
1. `br update <id> --status in_progress`
2. `jj log` — if empty unnamed commit below working commit, name it: `jj describe -m "..."`
3. `jj new` — fresh working commit
4. Do the work, run tests
5. `br close <id> --reason "Done"` — close BEFORE squash; this writes `.beads/issues.jsonl` into `@`, which gets included in the next squash
6. `jj squash --use-destination-message` then `jj describe -r @- -m "Present tense description"` — using `--use-destination-message` avoids the interactive editor that pops up when both commits already have descriptions
7. `jj log` — verify history shows correct author on each commit; `@` must be empty and unnamed

---

## br/jj Churn (only when user says "br/jj churn")

**Before first loop iteration** — verify jj identity (commits without author are broken):
```bash
jj config list --user
# Must show user.name and user.email. If missing:
jj config set --user user.name "Lachlan Kermode"
jj config set --user user.email "lachie@ohrg.org"
```

Loop until no open issues:
1. `br ready --json` — pick highest priority (bugs/tasks/features, not epics/chores)
2. Implement with br/jj workflow
3. `/clear` — clear context
4. Repeat

When done, run the project's formatter and linter (see the project's `CLAUDE.md` for exact
commands), then `jj squash --use-destination-message` if that produced changes. Leave `@` empty.

Report: list all closed issues.

---

## br/jj Pair (only when user says "br/jj pair")

**Before first loop iteration** — verify jj identity (commits without author are broken):
```bash
jj config list --user
# Must show user.name and user.email. If missing:
jj config set --user user.name "Lachlan Kermode"
jj config set --user user.email "lachie@ohrg.org"
```

Loop until no open issues or user stops:
1. `br ready --json` — pick highest priority (bugs/tasks/features, not epics/chores)
2. Implement with br/jj workflow
3. **Pause and prompt the user** — present what was done, ask whether to continue
   - User may review code, request changes, add/modify/remove br issues
   - Only continue to next issue when the user explicitly says to (e.g. "continue", "next", "go")
   - If user says "stop" or "done", exit the loop

When done, run the project's formatter and linter (see the project's `CLAUDE.md` for exact
commands), then `jj squash --use-destination-message` if that produced changes. Leave `@` empty.

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
