{ pkgs, ... }:
{
	home.packages = with pkgs; [
    # Freetube is a better form of youtube that allows you to browse without
    # the ads, and feed distractions.
    freetube
    yt-dlp
  ];
}
