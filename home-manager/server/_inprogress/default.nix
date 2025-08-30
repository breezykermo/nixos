{ config, pkgs, lib, ...}:
{

  imports = [
    # ./remouse
  ];

  home.packages = with pkgs; [
    devenv
    # minikube
    # kubernetes
    evince
    aider-chat
    typst
    delta
  ];

  programs = {
    # k9s.enable = true;
    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Lachlan Kermode";
          email = "lachie@ohrg.org";
        };
        ui.default-command = "diff";
        ui.pager = "delta";
        # ui.diff.format = "git";
        ui.diff-formatter = ":git";
      };
    };
  };
}
