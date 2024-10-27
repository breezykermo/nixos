{ config, pkgs, lib, ...}:
{
  home.packages = with pkgs: [
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
		# jujutsu = {
		# 	enable = true;
		# 	settings = {
		# 		user = {
		# 			name = "Lachlan Kermode";
		# 			email = "hi@ohrg.org";
		# 		};
		# 	};
		# };
  };
}
