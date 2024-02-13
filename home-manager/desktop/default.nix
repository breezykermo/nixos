{ pkgs, ... }:

{
  imports = [
    ./hypr
    ./firefox
    ./zathura
  ];

  home.packages = with pkgs; [
    xdg-utils
    # screenshots 
    slurp
    grim
    # citation management
    zotero

  ];
 
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ''
    ${builtins.readFile "${pkgs.waybar}/etc/xdg/waybar/style.css"}
    ${builtins.readFile ./waybar.style.css}
    '';
    settings = [{
      height = 5;
      layer = "top";
      position = "bottom";
      tray = { spacing = 10; };
      modules-center = [ "hyprland/window" ];
      modules-left = [ "hyprland/workspaces" "hyprland/mode" ];
      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "temperature"
        "battery"
        "clock"
        "tray"
      ];
      battery = {
        format = "{capacity}% {icon}";
        format-alt = "{time} {icon}";
        format-charging = "{capacity}% ";
        format-icons = [ "" "" "" "" "" ];
        format-plugged = "{capacity}% ";
        states = {
          critical = 15;
          warning = 30;
        };
      };
      clock = {
        format-alt = "{:%Y-%m-%d}";
        tooltip-format = "{:%Y-%m-%d | %H:%M}";
      };
      cpu = {
        format = "{usage}% ";
        tooltip = false;
      };
      memory = { format = "{}% "; };
      network = {
        interval = 1;
        format-alt = "{ifname}";
        format-disconnected = "Disconnected ⚠";
        format-ethernet = "{ifname}: {ipaddr}/{cidr}   up: {bandwidthUpBits} down: {bandwidthDownBits}";
        format-linked = "{ifname} (No IP) ";
        format-wifi = "{essid} ({signalStrength}%) ";
      };
      pulseaudio = {
        format = "{volume}% {icon} {format_source}";
        format-bluetooth = "{volume}% {icon} {format_source}";
        format-bluetooth-muted = " {icon} {format_source}";
        format-icons = {
          car = "";
          default = [ "" "" "" ];
          handsfree = "";
          headphones = "";
          headset = "";
          phone = "";
          portable = "";
        };
        format-muted = " {format_source}";
        format-source = "{volume}% ";
        format-source-muted = "";
        on-click = "pavucontrol";
      };
      "sway/mode" = { format = ''<span style="italic">{}</span>''; };
      temperature = {
        critical-threshold = 80;
        format = "{temperatureC}°C {icon}";
        format-icons = [ "" "" "" ];
      };
    }];
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = "480175";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      line-color = "ffffff";
      show-failed-attempts = true;
    };
  };

  programs.rofi = {
    enable = true;
    theme = "gruvbox-dark";
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "Fira Code";
        size = 12;
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
        { key = "C";  mods = "Control";   action = "Copy"; } 
        { key = "V";  mods = "Control";   action = "Paste"; } 
        { key = "J";  mods = "Shift|Alt"; action = "DecreaseFontSize"; } 
        { key = "K";  mods = "Shift|Alt"; action = "IncreaseFontSize"; } 
      ];
    };
  };
}
