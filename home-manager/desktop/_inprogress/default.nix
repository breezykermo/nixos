{ pkgs, ... }:
let 
  # windsurf = pkgs.callPackage ./windsurf.nix {};
in 
{
	home.packages = with pkgs; [
    sqlite
    (python313.withPackages(ps: with ps; [
      llm
      llm-ollama
      datasette
      # numpy
      # pandas
      # jupyterlab
    ]))
  ];
}
