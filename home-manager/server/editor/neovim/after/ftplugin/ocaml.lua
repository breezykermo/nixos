-- OxCaml (Jane Street's OCaml fork) adds syntax tree-sitter-ocaml doesn't parse
-- yet: mode/kind annotations (`@ local`, `: value mod portable`), `exclave_`,
-- unboxed types (`#(...)`, `#float#`). Those spans land in TS ERROR nodes and
-- render as a jarring red squiggly even though the code is valid. Real syntax
-- errors and type errors still surface via ocamllsp diagnostics (LSP virtual
-- text/underline), so it's safe to mute the treesitter-level error highlight
-- here without losing real error signal.
vim.api.nvim_set_hl(0, '@error.ocaml', { link = 'Normal' })
