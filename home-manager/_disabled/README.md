# Disabled Modules

This directory contains modules that are temporarily disabled or not currently in use.

## Status

- **gaming/** - Gaming configuration (Discord, Wine). Uncomment `./gaming` in `desktop/default.nix` to enable.
- **vscode/** - Visual Studio Code configuration. Uncomment `./vscode` in `desktop/default.nix` to enable.
- **irc/** - IRC client (weechat) configuration. Re-enable by uncommenting import in `server/default.nix`.

## Re-enabling Modules

To re-enable a module:

1. Move it back to its original location:
   - gaming: `mv _disabled/gaming ../desktop/`
   - vscode: `mv _disabled/vscode ../desktop/`
   - irc: `mv _disabled/irc ../server/`

2. Uncomment the import in the respective `default.nix` file

3. Run `just deploy` to apply changes
