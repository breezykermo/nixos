{
  config,
  lib,
  pkgs,
  ...
}: {
  # `programs.git` will generate the config file: ~/.config/git/config
  # to make git use this config file, `~/.gitconfig` should not exist!
  #
  #    https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    rm -f ~/.gitconfig
  '';

  home.packages = with pkgs; [
    # Automatically trims your branches whose tracking remote refs are merged or gone
    # It's really useful when you work on a project for a long time.
    git-trim
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Lachlan Kermode";
    userEmail = "lachlankermode@live.com";

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;

      # replace https with ssh
      # url = {
      #   "ssh://git@github.com/" = {
      #     insteadOf = "https://github.com/";
      #   };
      #   "ssh://git@gitlab.com/" = {
      #     insteadOf = "https://gitlab.com/";
      #   };
      #   "ssh://git@bitbucket.com/" = {
      #     insteadOf = "https://bitbucket.com/";
      #   };
      # };
    };

    # signing = {
    #   key = "xxx";
    #   signByDefault = true;
    # };

    # A syntax-highlighting pager in Rust(2019 ~ Now)
    delta = {
      enable = true;
      options = {
        diff-so-fancy = true;
        line-numbers = true;
        true-color = "always";
        # features => named groups of settings, used to keep related settings organized
        # features = "";
      };
    };
  };
}
