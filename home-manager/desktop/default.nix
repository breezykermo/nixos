{ pkgs, inputs, ... }:

{
  imports = [
    ./hypr
    ./bluetooth
    ./browsers
    ./zathura
    ./spotify
    ./obs
    ./blender
    ./office
    ./youtube
    ./_inprogress
    # ./vscode
  ];

  home.packages = with pkgs; [
    xdg-utils
    # handlr

    # screenshots 
    slurp
    grim

    # android control via USB
    scrcpy

    # clipboard
    wl-clipboard-rs # required for tmux-yank to copy to clipboard

    # citation management
    # 1. Log into account for zotero.org (lachlankermode@live.com). Wait for sync...
    # 2. Install Better BibTex: https://retorque.re/zotero-better-bibtex/installation/
    # 3. Export "My Library" (with "Keep updated") to lyt/references/master.bib
    # 4. Install 'Zotero Connector' for Firefox.
    zotero

    # 'secure' messaging
    # NB: services.keybase is already enabled in server/core.nix, required for this.
    keybase-gui

    # volume control
    pulsemixer

    # backlight (control with "sudo xbacklight -dec 20")
    acpilight

    # for flashing ZSA keyboards
    keymapp

    # for flashcards
    anki-bin

    # modern terminal
    inputs.ghostty.packages.x86_64-linux.default
  ];

  xdg.configFile."ghostty/config".source = ./ghostty-config;

  programs.rofi = {
    enable = true;
    theme = "gruvbox-dark";
  };
}
