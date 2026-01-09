{pkgs, inputs, system, lib, machineVars, theme, ...}:
{
  home.packages = with pkgs; [
    delta       # syntax-highlighting in git and jj diffs
    lazygit     # git tui client
    git-crypt   # encrypted git repos

    # Terminal-based diff viewer with interactive file tree navigation
    inputs.ftdv.packages.${system}.default
  ];

  home.shellAliases = {
    gt = "ftdv";
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

  # ftdv configuration
  xdg.configFile."ftdv/config.yaml".text = ''
    git:
      paging:
        pager: "delta --dark --paging=never --line-numbers --side-by-side -w=${"{{"}diffAreaWidth}}"
        colorArg: "always"
    theme:
      name: gruvbox-dark
      colors:
        tree_line: '${theme.colors.gray}'
        tree_selected_bg: '${theme.colors.bg2}'
        tree_selected_fg: '${theme.colors.yellow}'
        tree_directory: '${theme.colors.blue}'
        tree_file: '${theme.foreground}'
        status_added: '${theme.colors.green}'
        status_removed: '${theme.colors.red}'
        status_modified: '${theme.colors.yellow}'
        border: '${theme.colors.gray}'
        border_focused: '${theme.colors.aqua}'
        title: '${theme.colors.aqua}'
        status_bar_bg: '${theme.colors.bg1}'
        status_bar_fg: '${theme.foreground}'
        text_primary: '${theme.foreground}'
        text_secondary: '${theme.colors.fg2}'
        text_dim: '${theme.colors.gray}'
        background: '${theme.background}'
  '';
}
