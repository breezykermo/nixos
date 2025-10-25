{pkgs, inputs, system, naersk, ...}:
let
  naersk' = pkgs.callPackage naersk {};
in
{
  home.packages = with pkgs; [
    delta       # syntax-highlighting in git and jj diffs
    lazygit     # git tui client
    git-crypt   # encrypted git repos

    # Terminal-based diff viewer with interactive file tree navigation
    (naersk'.buildPackage rec {
      pname = "ftdv";
      version = "0.1.2";

      src = pkgs.fetchFromGitHub {
        owner = "breezykermo";
        repo = pname;
        rev = "v${version}";
        sha256 = "sha256-J1lWrfZeH/V1hckLGWDoeU6aKFoLimddzaTKMQ8sDs8=";
      };
    })
  ];

  home.shellAliases = {
    gt = "ftdv";
  };

  programs = {
    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Lachlan Kermode";
          email = "lachie@ohrg.org";
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
        user.name = "Lachlan Kermode";
        user.email = "lachiekermode@gmail.com";
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
        pager: "delta --dark --paging=never --line-numbers --side-by-side -w={{diffAreaWidth}}"
        colorArg: "always"
    theme:
      name: dark
      colors:
        tree_line: dark_gray
        tree_selected_bg: '#323246'
        tree_selected_fg: yellow
        tree_directory: blue
        tree_file: white
        status_added: green
        status_removed: red
        status_modified: yellow
        border: dark_gray
        border_focused: cyan
        title: cyan
        status_bar_bg: dark_gray
        status_bar_fg: white
        text_primary: white
        text_secondary: gray
        text_dim: dark_gray
        background: black
  '';
}
