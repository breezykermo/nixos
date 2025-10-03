{ pkgs, ... }:
let 
  # windsurf = pkgs.callPackage ./windsurf.nix {};
in 
{
	home.packages = with pkgs; [
    proton-pass
    sqlite
    (python313.withPackages(ps: with ps; [
      llm
      llm-ollama
      datasette
      beautifulsoup4

      libevdev
      paramiko
      pynput
      screeninfo
      evdev

      # numpy
      # pandas
      # jupyterlab
    ]))
    nodePackages.pnpm
    pdfpc
    # code-cursor
  ];
}
