{
  config,
  pkgs,
  inputs,
  system,
  lib,
  naersk,
  machineVars,
  theme,
  ...
}: let
  mkNaerskGithubPackage = import ../../../../pkgs/mkNaerskGithubPackage.nix {inherit pkgs naersk;};
  mix = theme.themeLib.mix;

  # `jjj` (jujutsu jump) — fzf-driven revset picker, after
  # https://oppi.li/posts/jjj/. Behaves exactly like `jj`, except the revision
  # is chosen interactively in fzf and spliced in as `-r <rev>`; every other arg
  # is passed straight through. Uses `builtin_log_oneline` so each change is a
  # single line whose first 7+ char field is the change-id (what awk extracts).
  jjj = pkgs.writeShellApplication {
    name = "jjj";
    runtimeInputs = with pkgs; [jujutsu fzf gawk];
    # awk expressions intentionally live in single quotes (no shell expansion).
    excludeShellChecks = ["SC2016"];
    text = builtins.readFile ./jjj.sh;
  };

  # tuicr's theme, shared by both config trees below (tuicr resolves local
  # themes from `<config dir>/themes/`, so each tree needs its own copy).
  # Mirrors the active system theme (see themes/default.nix) so tuicr's panels
  # blend with the Ghostty terminal background.
  tuicrSystemTheme = ''
    panel_bg = "${theme.background}"
    bg_highlight = "${theme.colors.bg2}"
    fg_primary = "${theme.foreground}"
    fg_secondary = "${theme.colors.fg2}"
    fg_dim = "${theme.colors.fg3}"

    diff_add = "${theme.colors.green}"
    diff_add_bg = "${mix theme.colors.green theme.background 0.25}"
    diff_del = "${theme.colors.red}"
    diff_del_bg = "${mix theme.colors.red theme.background 0.25}"
    diff_context = "${theme.foreground}"
    diff_hunk_header = "${theme.colors.blue}"
    expanded_context_fg = "${theme.colors.fg3}"

    syntax_add_bg = "${mix theme.colors.green theme.background 0.20}"
    syntax_del_bg = "${mix theme.colors.red theme.background 0.20}"

    file_added = "${theme.colors.green}"
    file_modified = "${theme.colors.yellow}"
    file_deleted = "${theme.colors.red}"
    file_renamed = "${theme.colors.purple}"

    reviewed = "${theme.colors.green}"
    pending = "${theme.colors.yellow}"

    comment_note = "${theme.colors.blue}"
    comment_suggestion = "${theme.colors.aqua}"
    comment_issue = "${theme.colors.red}"
    comment_praise = "${theme.colors.green}"

    border_focused = "${theme.activeBorder}"
    border_unfocused = "${theme.inactiveBorder}"
    status_bar_bg = "${theme.colors.bg1}"
    cursor_color = "${theme.colors.yellow}"
    cursor_line_bg = "${theme.colors.bg2}"
    branch_name = "${theme.colors.purple}"
    help_indicator = "${theme.colors.fg3}"

    message_info_fg = "${theme.background}"
    message_info_bg = "${theme.colors.blue}"
    message_warning_fg = "${theme.background}"
    message_warning_bg = "${theme.colors.yellow}"
    message_error_fg = "${theme.background}"
    message_error_bg = "${theme.colors.red}"
    update_badge_fg = "${theme.background}"
    update_badge_bg = "${theme.colors.yellow}"

    mode_fg = "${theme.background}"
    mode_bg = "${theme.activeBorder}"
  '';

  tuicrCommonConfig = ''
    theme = "system"
    transparent_background = true
    scroll_offset = 3
    wrap = true
  '';
in {
  # git TUI. Installed through the module (rather than home.packages) so its
  # colors can be driven from the palette; lazygit takes bare hex strings.
  programs.lazygit = {
    enable = true;
    settings.gui = {
      theme = {
        activeBorderColor = [theme.activeBorder "bold"];
        inactiveBorderColor = [theme.inactiveBorder];
        searchingActiveBorderColor = [theme.colors.yellow "bold"];
        optionsTextColor = [theme.colors.blue];
        selectedLineBgColor = [theme.colors.bg2];
        cherryPickedCommitBgColor = [theme.colors.bg2];
        cherryPickedCommitFgColor = [theme.colors.purple];
        markedBaseCommitBgColor = [theme.colors.bg2];
        markedBaseCommitFgColor = [theme.colors.yellow];
        unstagedChangesColor = [theme.colors.red];
        defaultFgColor = [theme.foreground];
      };
      authorColors."*" = theme.colors.purple;
    };
  };

  # lazygit writes an empty ~/.config/lazygit/config.yml the first time it runs,
  # and home-manager refuses to clobber a pre-existing file -- which fails
  # activation on any box where lazygit ran before this module existed. Nothing
  # in that file is ours to keep, so take ownership unconditionally.
  # (the module writes via home.file under $XDG_CONFIG_HOME, not xdg.configFile)
  home.file."${config.xdg.configHome}/lazygit/config.yml".force = true;

  home.packages = with pkgs; [
    delta # syntax-highlighting in git and jj diffs
    git-crypt # encrypted git repos

    # Syntax-aware merge/conflict-resolution tool. jj ships a default
    # merge-tools.mergiraf config out of the box (`jj config list --include-defaults
    # merge-tools | grep mergiraf`), so having the binary on PATH is all that's needed
    # for `jj resolve --tool mergiraf` (used by jj.nvim's resolve strategy, see
    # home-manager/server/editor/neovim/lua/plugins/init.lua).
    mergiraf

    # Code review TUI with vim keybindings (git/jj/mercurial)
    inputs.tuicr.packages.${system}.default

    jjj # fzf revset picker for jj (see let-binding above)

    # TUI for Jujutsu/jj
    (mkNaerskGithubPackage {
      name = "blazingjj";
      version = "0.8.0";
      owner = "blazingjj";
      sha256 = "0fvwb8haan7lvx5fz8y1wm4wnddp1lhn4rssls2aakrkg3vw7rxx";
    })
  ];

  home.shellAliases = {
    dj = "tuicr";
    jt = "blazingjj";
  };

  xdg.configFile = {
    # Standalone tuicr (the `dj` alias): file list hidden, whole-diff scroll.
    "tuicr/config.toml".text = tuicrCommonConfig + ''
      show_file_list = false
    '';
    "tuicr/themes/system.toml".text = tuicrSystemTheme;

    # Second config tree used ONLY when tuicr is launched from Neovim's jj log
    # (<C-d>, see home-manager/server/editor/neovim/lua/jjx/init.lua), which
    # sets XDG_CONFIG_HOME to ~/.config/tuicr-nvim for that job. tuicr resolves
    # its config as $XDG_CONFIG_HOME/tuicr/config.toml and local themes from the
    # sibling themes/ dir, hence the doubled `tuicr-nvim/tuicr/` path and the
    # duplicated theme file. Review-from-the-editor wants a file-tree-first
    # layout, so the file list is shown and single-file view is on; jjx sends
    # `;h` after launch to put the cursor in the tree.
    "tuicr-nvim/tuicr/config.toml".text = tuicrCommonConfig + ''
      show_file_list = true
      single_file_view = true
    '';
    "tuicr-nvim/tuicr/themes/system.toml".text = tuicrSystemTheme;
  };

  programs = {
    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = machineVars.userFullName;
          email = machineVars.jjEmail;
        };
        ui.default-command = "log";
        ui.pager = "delta";
        # Show the entire history by default (`::` = all commits) instead of jj's
        # truncated default revset. This governs bare `jj log` AND jj.nvim's log
        # buffer, including the refresh it does after <CR>/n/etc. -- so the full
        # view persists across those operations rather than snapping back to the
        # default revset.
        revsets.log = "::";
        # `jj ws` -- a workspace dashboard for concurrent-agent sessions. Each
        # `jj workspace add` gets its own working-copy commit, marked `<name>@`
        # in the log; this narrows the full `::` view to just trunk, everything
        # built on it, and every workspace's tip, so who-is-where is legible at
        # a glance. `working_copies()` covers all workspaces including the
        # current one; the bare `trunk()` term anchors the graph so the stacks
        # render connected rather than as floating fragments. Caveat: jj only
        # snapshots the CURRENT workspace's working copy, so a sibling's
        # uncommitted edits read as `(empty)` here until a jj command runs
        # inside that workspace's own root.
        aliases.ws = [
          "log"
          "-r"
          "trunk() | trunk().. | working_copies()"
        ];
        ui.diff-formatter = ":git";
        # jj defaults timestamps to cyan; blue reads better against the active
        # terminal/Neovim theme.
        colors.timestamp = "blue";
        colors."working_copy timestamp" = "bright blue";
      };
    };

    git = {
      enable = true;
      lfs.enable = true;
      signing.format = null;
      settings = {
        user.name = machineVars.userFullName;
        user.email = machineVars.userEmail;
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        core.editor = "$EDITOR";
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        delta.navigate = true;
        delta.dark = true;
        # Palette-driven delta colors (delta is also jj's diff pager, so this
        # covers `jj diff`/`jj show` too). The *-style values are
        # "<fg> <bg>" pairs; the backgrounds are the same palette-mixed washes
        # tuicr uses above, so a diff reads the same in either tool.
        delta.syntax-theme = "ansi";
        delta.minus-style = "normal ${mix theme.colors.red theme.background 0.25}";
        delta.minus-emph-style = "normal ${mix theme.colors.red theme.background 0.45}";
        delta.plus-style = "normal ${mix theme.colors.green theme.background 0.25}";
        delta.plus-emph-style = "normal ${mix theme.colors.green theme.background 0.45}";
        delta.hunk-header-style = "${theme.colors.blue} bold";
        delta.hunk-header-decoration-style = "${theme.colors.bg3} box";
        delta.file-style = "${theme.colors.purple} bold";
        delta.file-decoration-style = "${theme.colors.bg3} ul";
        delta.line-numbers-left-style = theme.colors.fg4;
        delta.line-numbers-right-style = theme.colors.fg4;
        delta.line-numbers-minus-style = theme.colors.red;
        delta.line-numbers-plus-style = theme.colors.green;
        delta.line-numbers-zero-style = theme.colors.fg4;
        merge.conflictStyle = "zdiff3";
      };
    };

    fish.functions = {
      jjdone = {
        description = "Set main bookmark to parent, and push to git";
        body = ''
          jj b set main -r '@-'
          jj git push
        '';
      };
    };
  };
}
