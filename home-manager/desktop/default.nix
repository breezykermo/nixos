{ pkgs, ... }:

{
  imports = [
    ./hypr
    ./vscode
    ./bluetooth
    ./firefox
    ./zathura
    ./spotify
    ./obs
    ./blender
    ./office
    ./youtube
    ./_inprogress
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
  ];

  programs.rofi = {
    enable = true;
    theme = "gruvbox-dark";
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window.decorations = "none";
      window.opacity = 0.9;
      scrolling.history = 0;
      terminal.shell = {
        program = "${pkgs.tmux}/bin/tmux";
        args = [ "attach-session" "-t" "." "-c" "/home/alice/Brown Dropbox/Lachlan Kermode/lyt" ];
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
