{
  lib,
  config,
  ...
}: {
  options.gui.zathura = with lib; {
    enable = mkEnableOption "zathura document viewer";
  };

  config = lib.mkIf config.gui.zathura.enable {
    programs.zathura = {
      enable = true;
      options = {
        font = "Diosevka 10";
        default-bg = "#1d2021";
        default-fg = "#ebdbb2";
        highlight-color = "#d79921";
        highlight-fg = "#d79921";
        highlight-active-color = "#98971a";
        page-padding = 12;
        notification-bg = "#3c3836";
        notification-fg = "#d79921";
        notification-warning-bg = "#3c3836";
        notification-warning-fg = "#d65d0e";
        notification-error-bg = "#3c3836";
        notification-error-fg = "#cc241d";
        statusbar-bg = "#3c3836";
        statusbar-fg = "#ebdbb2";
        statusbar-h-padding = 24;
        statusbar-v-padding = 12;
        window-title-basename = true;
        window-title-page = true;
        statusbar-home-tilde = true;
      };
    };
  };
}
