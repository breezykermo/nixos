{ pkgs, inputs, lib, theme, ... }:
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
    ./remarkable
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
    desktop-notifications = true

    command = tmux attach-session -t .

    keybind = ctrl+v=paste_from_clipboard
    keybind = shift+alt+j=increase_font_size:1
    keybind = shift+alt+k=decrease_font_size:1
  '';

  programs.rofi = {
    enable = true;
    theme = "${theme.rofiTheme}";
  };

  # Notification daemon for Wayland/Hyprland
  services.mako = {
    enable = true;
    settings = {
      "" = {
        background-color = "${theme.background}";
        text-color = "${theme.foreground}";
        border-color = "${theme.colors.blue}";
        border-radius = 0;
        border-size = 2;
        default-timeout = 5000;
        font = "Berkeley Mono Nerd Font Mono 11";
        icons = true;
        max-visible = 3;
        layer = "overlay";
      };
    };
  };
}
