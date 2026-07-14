# jj.nvim cheat sheet

`jj.nvim` (see `home-manager/server/neovim/lua/plugins/init.lua`) brings Jujutsu into
Neovim. These are the default keymaps — none are remapped here except `gr`'s resolve
strategy and the log buffer's window layout.

## Opening it

- `:J log` — open the log buffer (main entry point). Opens as a full-height vertical
  split (configured via `terminal.window.type = 'vsplit'`).
- `:Jdiff [rev]` / `:Jhdiff [rev]` — vertical/horizontal diff split against a revision
- `:Jbrowse [rev]` — open current file/line on remote (GitHub/GitLab/etc.)
- `:J <subcommand>` — raw passthrough, e.g. `:J status`, `:J new`

## From the log buffer, cursor on a revision

| Key | Action |
|---|---|
| `<CR>` | edit revision |
| `<S-CR>` | edit revision (ignore immutability) |
| `d` | describe (commit message editor) |
| `<S-d>` | diff revision |
| `n` | new change branching off cursor |
| `<C-n>` / `<S-n>` | new change after (/ ignore immutability) |
| `gr` | **resolve conflicts** — runs mergiraf here; auto-opens `jj-diffconflicts` if markers remain |
| `s` / `<S-s>` | enter squash mode / quick-squash into parent |
| `<C-s>` | split revision (floating terminal) |
| `r` | enter rebase mode (`<CR>`/`o` onto, `a` after, `b` before, `<S-*>` = ignore immutability) |
| `<C-y>` | enter duplicate mode (same onto/after/before scheme) |
| `a` | abandon revision |
| `b` / `B` | create-or-move / delete bookmark |
| `<S-t>` | create tag |
| `f` | fetch |
| `p` / `<S-p>` | push revision's bookmark / push via picker |
| `o` / `<S-o>` | open PR/MR / pick remote first |
| `<S-u>` / `<S-r>` | undo / redo last op |
| `<C-r>` | change displayed revset |
| `<S-k>` (x2) | open file-summary tooltip, then enter it — `<CR>` inside opens the file at that revision |
| `<S-h>` (visual, multi-select) | diff-history between selected revisions |

Status buffer: `<CR>` opens file, `<S-x>` restores file.

## Local customizations

- `gr` resolves with **mergiraf only** (see `home-manager/server/vcs/default.nix` for the
  package, `lua/plugins/init.lua` for the single `resolve_strategies` entry) — no picker
  prompt, since there's only one strategy configured.
- Opening a still-conflicted file (via `<S-k>` -> `<CR>`, or any other route) auto-launches
  `jj-diffconflicts` for manual per-hunk resolution, via the `BufReadPost` autocmd in
  `lua/config/autocmds.lua` that detects jj's default "diff" conflict marker style
  (`<<<<<<< conflict N of M`).
- A separate autocmd in the same file works around an upstream jj.nvim bug where opening
  a file from the log buffer's summary tooltip can hit `E1513: Cannot switch buffer`
  (stuck `winfixbuf` on the log/tooltip window).
