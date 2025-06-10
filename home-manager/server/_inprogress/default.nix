{ config, pkgs, lib, ...}:
{

  imports = [
    ./remouse
  ];

  home.packages = with pkgs; [
    devenv
    # minikube
    # kubernetes
    evince
    aider-chat
    typst
    # interactively fold JSON
    # (rustPlatform.buildRustPackage rec {
    #   pname = "jless";
    #   version = "0.9.0";
    #
    #   src = fetchCrate {
    #     inherit pname version;
    #     hash = "sha256-YDZT7CBhQGIC4OSUDfOxbtT2tDgpJY0jYtG6EcjoW0Y=";
    #   };
    #
    #   cargoHash = "sha256-sas94liAOSIirIJGdexdApXic2gWIBDT4uJFRM3qMw0=";
    # })

  ];

  programs = {
    # k9s.enable = true;
		jujutsu = {
			enable = true;
      settings = {
        user = {
          name = "Lachlan Kermode";
          email = "lachie@ohrg.org";
          ui.default.command = "log";
        };
      };
		};
  };
}
