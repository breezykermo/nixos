{ pkgs, ... }:
{

	home.packages = with pkgs; [
    # slice and dice CSVs 
    # (rustPlatform.buildRustPackage rec {
    #   pname = "qsv";
    #   version = "0.132.0";
    #
    #   src = fetchCrate {
    #     inherit pname version;
    #     hash = "sha256-3NzJau4ckCLOOaoxoUWwi4mCNJJGchrvhfa41rlQvWo="; 
    #   };
    #
    #   cargoHash = lib.fakeHash;
    #
    #   nativeBuildInputs = [];
    # })
  ];
}
