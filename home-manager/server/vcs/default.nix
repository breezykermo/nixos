{pkgs, inputs, system, lib, naersk, machineVars, ...}:
let
  naersk' = pkgs.callPackage naersk {};
in
{
  home.packages = with pkgs; [
    delta       # syntax-highlighting in git and jj diffs
    lazygit     # git tui client
    git-crypt   # encrypted git repos

    # Code review TUI with vim keybindings (git/jj/mercurial)
    inputs.tuicr.packages.${system}.default

    # TUI for Jujutsu/jj
    (naersk'.buildPackage rec {
      name = "blazingjj";
      version = "0.8.0";

      src = fetchFromGitHub {
        owner = "blazingjj";
        repo = name;
        rev = "v${version}";
        sha256 = "0fvwb8haan7lvx5fz8y1wm4wnddp1lhn4rssls2aakrkg3vw7rxx";
      };
    })
  ];

  home.shellAliases = {
    dj = "tuicr";
    jt = "blazingjj";
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
