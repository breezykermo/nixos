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
  ];

  programs = {
    # k9s.enable = true;
  };
}
