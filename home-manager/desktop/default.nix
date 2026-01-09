{ pkgs, inputs, lib, ... }:

let
  theme = import ../../themes/default.nix { inherit lib; };
in
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
  ];

  home.packages = with pkgs; [
    xdg-utils

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

    # GTK/GSettings support (needed for GTK file chooser dialogs)
    gsettings-desktop-schemas
    glib
  ];

  xdg.configFile."ghostty/config".text = ''
    shell-integration = fish

    background = ${theme.background}
    background-opacity = ${theme.transparency.opacity}
    window-theme = ghostty
    window-decoration = false
    window-padding-y = 0
    cursor-style = underline
    cursor-style-blink = true

    font-family = "Berkeley Mono Nerd Font Mono"
    font-size = 12

    copy-on-select = true

    command = tmux attach-session -t .

    keybind = ctrl+v=paste_from_clipboard
    keybind = shift+alt+j=increase_font_size:1
    keybind = shift+alt+k=decrease_font_size:1
  '';

  programs.rofi = {
    enable = true;
    theme = "${theme.rofiTheme}";
  };
}
