{
  pkgs,
  inputs,
  system,
  lib,
  naersk,
  machineVars,
  theme,
  ...
}: let
  mkNaerskGithubPackage = import ../../../pkgs/mkNaerskGithubPackage.nix {inherit pkgs naersk;};
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
in {
  home.packages = with pkgs; [
    delta # syntax-highlighting in git and jj diffs
    lazygit # git tui client
    git-crypt # encrypted git repos

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
    "tuicr/config.toml".text = ''
      theme = "system"
      transparent_background = true
      show_file_list = false
      scroll_offset = 3
      wrap = true
    '';

    # Local theme that mirrors the active system theme (see themes/default.nix),
    # so tuicr's panels blend with the Ghostty terminal background.
    "tuicr/themes/system.toml".text = ''
      panel_bg = "${theme.background}"
      bg_highlight = "${theme.colors.bg2}"
      fg_primary = "${theme.foreground}"
      fg_secondary = "${theme.colors.fg2}"
      fg_dim = "${theme.colors.fg3}"

      diff_add = "#50fa7b"
      diff_add_bg = "${mix "#50fa7b" theme.background 0.25}"
      diff_del = "#ff5555"
      diff_del_bg = "${mix "#ff5555" theme.background 0.25}"
      diff_context = "${theme.foreground}"
      diff_hunk_header = "${theme.colors.blue}"
      expanded_context_fg = "${theme.colors.fg3}"

      syntax_add_bg = "${mix "#50fa7b" theme.background 0.20}"
      syntax_del_bg = "${mix "#ff5555" theme.background 0.20}"

      file_added = "#50fa7b"
      file_modified = "${theme.colors.yellow}"
      file_deleted = "#ff5555"
      file_renamed = "${theme.colors.purple}"

      reviewed = "#50fa7b"
      pending = "${theme.colors.yellow}"

      comment_note = "${theme.colors.blue}"
      comment_suggestion = "${theme.colors.aqua}"
      comment_issue = "#ff5555"
      comment_praise = "#50fa7b"

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
      message_error_bg = "#ff5555"
      update_badge_fg = "${theme.background}"
      update_badge_bg = "${theme.colors.yellow}"

      mode_fg = "${theme.background}"
      mode_bg = "${theme.activeBorder}"
    '';
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
        ui.diff-formatter = ":git";
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
