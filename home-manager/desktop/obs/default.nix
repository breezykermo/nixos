{ pkgs, ... }:
{

	home.packages = with pkgs; [
    vlc
  ];

  programs.obs-studio = {
    enable = true;
    # see https://mynixos.com/packages/obs-studio-plugins
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      droidcam-obs
      obs-composite-blur
      obs-move-transition
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vertical-canvas
    ];
  };
}
