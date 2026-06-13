{ pkgs, inputs, lib, theme, localProfile, config, ... }:
{
  imports = [
    ./hypr
    ./bluetooth
    ./browsers
    ./zathura
    ./spotify
    ./office
    ./youtube
    ./protonvpn
    ./_inprogress
  ] ++ lib.optionals (localProfile == "homework") [
    # Software only needed on the "homework" machine
    ./obs
    ./remarkable
    ./blender
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
    foreground = ${theme.foreground}
    cursor-color = ${theme.foreground}
    cursor-text = ${theme.background}
    selection-background = ${theme.colors.bg2}
    selection-foreground = ${theme.foreground}

    palette = 0=${theme.colors.bg2}
    palette = 1=${theme.colors.red}
    palette = 2=${theme.colors.green}
    palette = 3=${theme.colors.yellow}
    palette = 4=${theme.colors.blue}
    palette = 5=${theme.colors.purple}
    palette = 6=${theme.colors.aqua}
    palette = 7=${theme.colors.fg2}
    palette = 8=${theme.colors.gray}
    palette = 9=${theme.colors.bright_red}
    palette = 10=${theme.colors.bright_green}
    palette = 11=${theme.colors.bright_yellow}
    palette = 12=${theme.colors.bright_blue}
    palette = 13=${theme.colors.bright_purple}
    palette = 14=${theme.colors.bright_aqua}
    palette = 15=${theme.colors.fg0}

    window-theme = ghostty
    window-decoration = false
    window-padding-y = 0
    cursor-style = underline
    cursor-style-blink = true

    font-family = "Berkeley Mono Nerd Font Mono"
    font-size = 12

    copy-on-select = true
    desktop-notifications = true

    command = tmux attach || tmux new-session

    keybind = ctrl+v=paste_from_clipboard
    keybind = shift+alt+j=increase_font_size:1
    keybind = shift+alt+k=decrease_font_size:1
  '';

  programs.rofi = {
    enable = true;
    theme =
      if theme.name == "rosepine" then
        let
          inherit (config.lib.formats.rasi) mkLiteral;
          c = theme.colors;
        in
        {
          "*" = {
            background = mkLiteral theme.background;
            background-alt = mkLiteral c.bg1;
            foreground = mkLiteral theme.foreground;
            selected = mkLiteral c.purple;
            active = mkLiteral c.aqua;
            urgent = mkLiteral c.red;

            background-color = mkLiteral "@background";
            text-color = mkLiteral "@foreground";
            border-color = mkLiteral "@selected";
            separatorcolor = mkLiteral "@background-alt";
            spacing = 2;
          };

          window = {
            background-color = mkLiteral "@background";
            border = 1;
            padding = 5;
          };

          mainbox = {
            border = 0;
            padding = 0;
          };

          message = {
            border = mkLiteral "1px dash 0px 0px";
            border-color = mkLiteral "@separatorcolor";
            padding = mkLiteral "1px";
          };

          textbox = {
            text-color = mkLiteral "@foreground";
          };

          listview = {
            fixed-height = 0;
            border = mkLiteral "2px dash 0px 0px";
            border-color = mkLiteral "@separatorcolor";
            spacing = mkLiteral "2px";
            scrollbar = true;
            padding = mkLiteral "2px 0px 0px";
          };

          element = {
            border = 0;
            padding = mkLiteral "1px";
          };

          "element-text" = {
            background-color = mkLiteral "inherit";
            text-color = mkLiteral "inherit";
          };

          "element.normal.normal" = {
            background-color = mkLiteral "@background";
            text-color = mkLiteral "@foreground";
          };

          "element.normal.urgent" = {
            background-color = mkLiteral "@background";
            text-color = mkLiteral "@urgent";
          };

          "element.normal.active" = {
            background-color = mkLiteral "@background";
            text-color = mkLiteral "@active";
          };

          "element.selected.normal" = {
            background-color = mkLiteral "@selected";
            text-color = mkLiteral "@background";
          };

          "element.selected.urgent" = {
            background-color = mkLiteral "@urgent";
            text-color = mkLiteral "@background";
          };

          "element.selected.active" = {
            background-color = mkLiteral "@active";
            text-color = mkLiteral "@background";
          };

          "element.alternate.normal" = {
            background-color = mkLiteral "@background-alt";
            text-color = mkLiteral "@foreground";
          };

          scrollbar = {
            width = mkLiteral "4px";
            border = 0;
            handle-width = mkLiteral "8px";
            padding = 0;
          };

          "mode-switcher" = {
            border = mkLiteral "2px dash 0px 0px";
            border-color = mkLiteral "@separatorcolor";
          };

          "button.selected" = {
            background-color = mkLiteral "@selected";
            text-color = mkLiteral "@background";
          };

          inputbar = {
            spacing = 0;
            text-color = mkLiteral "@foreground";
            padding = mkLiteral "1px";
            children = map mkLiteral [ "prompt" "textbox-prompt-colon" "entry" "case-indicator" ];
          };

          prompt = {
            spacing = 0;
            text-color = mkLiteral "@foreground";
          };

          entry = {
            spacing = 0;
            text-color = mkLiteral "@foreground";
          };

          "case-indicator" = {
            spacing = 0;
            text-color = mkLiteral "@foreground";
          };

          "textbox-prompt-colon" = {
            expand = false;
            str = ":";
            margin = mkLiteral "0px 0.3em 0em 0em";
            text-color = mkLiteral "@foreground";
          };
        }
      else
        "${theme.rofiTheme}";
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
        # Left-clicking a notification invokes its default action (instead of
        # just dismissing) so Claude Code's "session needs attention" popups can
        # focus the originating terminal. Notifications without a default action
        # still dismiss on left-click.
        on-button-left = "invoke-default-action";
      };
    };
  };
}
