{ pkgs, ... }:

{
  imports = [
    ./hypr
    ./firefox
    ./zathura
    ./spotify
    ./obs
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
      scrolling.history = 0;
      shell = {
        program = "${pkgs.fish}/bin/fish";
        args = [ "--interactive" ];
      };
      colors = {
        draw_bold_text_with_bright_colors = true;
        primary = {
          background = "0x1d2021";
          foreground = "0xd5c4a1";
        };
        cursor = {
          text = "0x1d2021";
          cursor = "0xd5c4a1";
        };
        bright = {
          black =   "0x665c54";
          red =     "0xfe8019";
          green =   "0x3c3836";
          yellow =  "0x504945";
          blue =    "0xbdae93";
          magenta = "0xebdbb2";
          cyan =    "0xd65d0e";
          white =   "0xfbf1c7";
        };
        normal = {
          black =   "0x1d2021";
          red =     "0xfb4934";
          green =   "0xb8bb26";
          yellow =  "0xfabd2f";
          blue =    "0x83a598";
          magenta = "0xd3869b";
          cyan =    "0x8ec07c";
          white =   "0xd5c4a3";
        };
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
