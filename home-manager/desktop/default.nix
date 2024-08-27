{ pkgs, ... }:

{
  imports = [
    ./hypr
    # ./bluetooth
    ./firefox
    ./zathura
    ./spotify
    ./obs
    ./blender
    ./office
  ];

  home.packages = with pkgs; [
    xdg-utils
    # handlr

    # screenshots 
    slurp
    grim

    # clipboard
    wl-clipboard-rs # required for tmux-yank to copy to clipboard

    # citation management
    zotero

    # 1. Log into account for zotero.org (lachlankermode@live.com). Wait for sync...
    # 2. Install Better BibTex: https://retorque.re/zotero-better-bibtex/installation/
    # 3. Export "My Library" (with "Keep updated") to lyt/references/master.bib
    # 4. Install 'Zotero Connector' for Firefox.
    imagemagick

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

  ];

  programs.rofi = {
    enable = true;
    theme = "gruvbox-dark";
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "Fira Code";
        size = 14;
      };
      window.decorations = "none";
      window.opacity = 0.8;
      scrolling.history = 0;
      shell = {
        program = "${pkgs.tmux}/bin/tmux";
        args = [ "new-session" ];
      };
      keyboard.bindings = [
        { key = "C";  mods = "Option";   action = "Copy"; } 
        { key = "V";  mods = "Control";   action = "Paste"; } 
        { key = "J";  mods = "Shift|Alt"; action = "DecreaseFontSize"; } 
        { key = "K";  mods = "Shift|Alt"; action = "IncreaseFontSize"; } 
      ];
    };
  };
}
