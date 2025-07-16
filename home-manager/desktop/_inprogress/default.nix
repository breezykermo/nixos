{ pkgs, ... }:
let 
  # windsurf = pkgs.callPackage ./windsurf.nix {};
in 
{
	home.packages = with pkgs; [
    # NOTE: must purchase the source code, and link to it via:
    #   nix-store --add-fixed sha256 rcu-d2024.001q-source.tar.gz
    rcu
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
    code-cursor
  ];
}
