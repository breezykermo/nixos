{
  lib,
  config,
  pkgs,
  ...
}: {
  options.gui.hyprland = with lib; {
    enable = mkEnableOption "hyprland window manager";
    keyboardLayout = mkOption {
      type = types.enum ["us-international" "se"];
      default = "us-international";
    };

    theme = mkOption {
      type = types.enum ["dark" "light"];
      default = "dark";
      example = "light";
    };
  };

  config = let
    cfg = config.gui.hyprland;
    playerctl = "${pkgs.playerctl}/bin/playerctl";
    raw-browser-open = "${pkgs.raw-browser-open}/bin/raw-browser-open";
    monitorString = with config.gui.monitor; "${name},${toString width}x${toString height}@${toString refreshRate},0x0,${toString scale}";
    brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
    wlrctl = "${pkgs.wlrctl}/bin/wlrctl";
    swaybg = "${pkgs.swaybg}/bin/swaybg";
    wf-recorder = "${pkgs.wf-recorder}/bin/wf-recorder";
    slurp = "${pkgs.slurp}/bin/slurp";
    grim = "${pkgs.grim}/bin/grim";
    wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
    notify-desktop = "${pkgs.notify-desktop}/bin/notify-desktop";

    step = toString 5;

    vrr = toString (
      if config.gui.monitor.variableRefreshRate
      then 1
      else 0
    );

    # TODO: Use config.services.xserver.xkbConfig
    keyboardConfig =
      if cfg.keyboardLayout == "us-international"
      then ''
        kb_layout=us
        kb_variant=altgr-intl
      ''
      else ''
        kb_layout=se
      '';

    activeBorder =
      if cfg.theme == "light"
      then "0xfffbf1c7"
      else "0xff3c3836";

    inactiveBorder =
      if cfg.theme == "light"
      then "0xffebdbb2"
      else "0xff282828";

    groupBorder =
      if cfg.theme == "light"
      then "0xffd5c4a1"
      else "0xff504945";

    groupBorderActive =
      if cfg.theme == "light"
      then "0xffbdae93"
      else "0xff665c54";

    background =
      if cfg.theme == "light"
      then "##d5c4a1" # NOTE: This escapes the hashtag (thanks Hyprland...)
      else "##141414";
  in
    lib.mkIf cfg.enable {
      wayland.windowManager.hyprland = {
        enable = true;
        recommendedEnvironment = true;
        extraConfig = ''
          monitor=${monitorString}

          general {
            gaps_in=8
            gaps_out=16
            border_size=2
            col.active_border=${activeBorder}
            col.inactive_border=${inactiveBorder}
            col.group_border=${groupBorder}
            col.group_border_active=${groupBorderActive}
            cursor_inactive_timeout=4 # This messes up game cursors :(
          }

          dwindle {
            force_split=2
          }

          input {
            ${keyboardConfig}
            repeat_rate=50
            repeat_delay=200

            touchpad {
              natural_scroll=true
            }
          }

          gestures {
            workspace_swipe=true
            workspace_swipe_distance=100
            workspace_swipe_cancel_ratio=0.0
          }

          decoration {
            rounding=${toString (4 * config.gui.monitor.scale)}
            drop_shadow=false
            dim_inactive=true
            dim_strength=0.2
            blur {
              enabled=false
            }
          }

          misc {
            disable_hyprland_logo=true
            disable_splash_rendering=true
            vrr=${vrr}
            render_titles_in_groupbar=false
          }

          animation=global,1,2,default
          animation=windows,1,2,default,slide

          # ======== BINDINGS ======== #
          # ======== Mouse ======== #
          bindm=SUPER,mouse:272,movewindow
          bindm=SUPER,mouse:273,resizewindow
          # bind=,mouse:277, # Fn 1
          # bind=,mouse:278, # Fn 2
          bind=,mouse:279,exec,${wlrctl} pointer click middle # Fn 3

          # ======== XF86 buttons ======== #
          bind=,XF86AudioPlay,exec,${playerctl} play
          bind=,XF86AudioPause,exec,${playerctl} pause
          bind=,XF86AudioPrev,exec,${playerctl} previous
          bind=,XF86AudioNext,exec,${playerctl} next
          bind=,XF86AudioStop,exec,${playerctl} stop

          bind=,XF86AudioRaiseVolume,exec,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ ${step}%+
          bind=,XF86AudioLowerVolume,exec,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ ${step}%-
          bind=,XF86AudioMute,exec,${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle
          bind=,XF86AudioMicMute,exec,${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle

          bind=,XF86MonBrightnessUp,exec,${brightnessctl} set +${step}%
          bind=,XF86MonBrightnessDown,exec,${brightnessctl} set ${step}%-

          # ======== XF86 replacements ======== #
          bind=SUPER,p,exec,${playerctl} play-pause
          bind=SUPER,n,exec,${playerctl} next
          bind=SUPERSHIFT,n,exec,${playerctl} previous

          bind=SUPER,b,exec,${brightnessctl} set ${step}%+
          bind=SUPERSHIFT,b,exec,${brightnessctl} set ${step}%-
          bind=SUPERCONTROL,b,exec,${brightnessctl} set $(rofi -dmenu -l 0 -p 'Brightness: ')%

          bind=SUPER,v,exec,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ ${step}%+
          bind=SUPERSHIFT,v,exec,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ ${step}%-
          bind=SUPERCONTROL,v,exec,${wpctl} set-volume @DEFAULT_AUDIO_SINK@ $(rofi -dmenu -l 0 -p "Volume:")%
          bind=SUPER,m,exec,${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle
          bind=SUPERSHIFT,m,exec,${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle

          # ======== Shortcuts ======== #
          bind=SUPER,Space,exec,rofi -modi drun -show drun -show-icons -matching fuzzy -drun-match-fields name -display-drun 'launch: '
          bind=SUPER,Return,exec,$TERM
          bind=SUPER,w,exec,${raw-browser-open}

          # Screenshot
          bind=SUPER,g,exec,${grim} - | ${wl-copy} -t image/png && ${notify-desktop} "Screenshot taken" "and copied to the clipboard"
          bind=SUPERSHIFT,g,exec,${grim} -g "$(${slurp} -b 28282877 -c d64d0e)" - | ${wl-copy} -t image/png && ${notify-desktop} "Screenshot taken" "and copied to the clipboard"

          # Screen record
          bind=SUPER,r,exec,pkill -SIGINT wf-recorder &&  ${notify-desktop} "Screen recording stopped" "and saved to ~/recording.mp4" || ${wf-recorder} -a <<<Y
          bind=SUPERSHIFT,r,exec,pkill -SIGINT wf-recorder && ${notify-desktop} "Screen recording stopped" "and saved to ~/recording.mp4" || ${wf-recorder} <<<Y

          # Unicode insert
          bind=SUPER,i,exec,wtype $(cat ${pkgs.unicode-character-list} | rofi -dmenu -p 'Insert: ' -i -matching fuzzy | cut -f 1)

          # Droidcam toggle
          bind=SUPER,d,exec,pkill -SIGHUP droidcam-cli || droidcam-cli adb 4747 -size 640x480

          # Screen zoom thing
          bind=SUPER,x,exec,grim - | imv -f -c 'bind <Escape> quit' -

          # ======== Window management ======== #
          bind=SUPER,f,fullscreen,0
          bind=SUPERSHIFT,f,togglefloating,
          bind=SUPER,t,togglegroup,
          bind=SUPER,c,changegroupactive

          bind=SUPER,Escape,exec,systemctl suspend
          bind=SUPERSHIFT,Escape,exit,
          bind=SUPER,q,killactive,

          # ======== Window navigation ======== #
          bind=SUPER,left,movefocus,l
          bind=SUPER,right,movefocus,r
          bind=SUPER,up,movefocus,u
          bind=SUPER,down,movefocus,d

          bind=SUPER,h,movefocus,l
          bind=SUPER,l,movefocus,r
          bind=SUPER,k,movefocus,u
          bind=SUPER,j,movefocus,d

          binde=SUPERSHIFT,left,resizeactive,-32 0
          binde=SUPERSHIFT,right,resizeactive,32 0
          binde=SUPERSHIFT,up,resizeactive,0 -32
          binde=SUPERSHIFT,down,resizeactive,0 32

          binde=SUPERSHIFT,h,resizeactive,-32 0
          binde=SUPERSHIFT,l,resizeactive,32 0
          binde=SUPERSHIFT,k,resizeactive,0 -32
          binde=SUPERSHIFT,j,resizeactive,0 32

          bind=SUPERCONTROL,left,movewindow,l
          bind=SUPERCONTROL,right,movewindow,r
          bind=SUPERCONTROL,up,movewindow,u
          bind=SUPERCONTROL,down,movewindow,d

          bind=SUPERCONTROL,h,movewindow,l
          bind=SUPERCONTROL,l,movewindow,r
          bind=SUPERCONTROL,k,movewindow,u
          bind=SUPERCONTROL,j,movewindow,d

          bind=SUPER,1,workspace,1
          bind=SUPER,2,workspace,2
          bind=SUPER,3,workspace,3
          bind=SUPER,4,workspace,4
          bind=SUPER,5,workspace,5
          bind=SUPER,6,workspace,6
          bind=SUPER,7,workspace,7
          bind=SUPER,8,workspace,8
          bind=SUPER,9,workspace,9
          bind=SUPER,0,workspace,10

          bind=SUPERSHIFT,1,movetoworkspace,1
          bind=SUPERSHIFT,2,movetoworkspace,2
          bind=SUPERSHIFT,3,movetoworkspace,3
          bind=SUPERSHIFT,4,movetoworkspace,4
          bind=SUPERSHIFT,5,movetoworkspace,5
          bind=SUPERSHIFT,6,movetoworkspace,6
          bind=SUPERSHIFT,7,movetoworkspace,7
          bind=SUPERSHIFT,8,movetoworkspace,8
          bind=SUPERSHIFT,9,movetoworkspace,9
          bind=SUPERSHIFT,0,movetoworkspace,10

          bind=SUPERCONTROL,1,movetoworkspacesilent,1
          bind=SUPERCONTROL,2,movetoworkspacesilent,2
          bind=SUPERCONTROL,3,movetoworkspacesilent,3
          bind=SUPERCONTROL,4,movetoworkspacesilent,4
          bind=SUPERCONTROL,5,movetoworkspacesilent,5
          bind=SUPERCONTROL,6,movetoworkspacesilent,6
          bind=SUPERCONTROL,7,movetoworkspacesilent,7
          bind=SUPERCONTROL,8,movetoworkspacesilent,8
          bind=SUPERCONTROL,9,movetoworkspacesilent,9
          bind=SUPERCONTROL,0,movetoworkspacesilent,10

          exec-once=waybar
          exec=${swaybg} -c "${background}"
        '';
      };
    };
}
