{
  lib,
  config,
  ...
}: {
  options.tui.pass = {
    enable = lib.mkEnableOption "the pass passowrd manager";
  };

  config = lib.mkIf config.tui.pass.enable {
    programs = {
      password-store = {
        enable = true;
        settings = {
          PASSWORD_STORE_DIR = "${config.home.homeDirectory}/pass";
        };
      };

      gpg.enable = true;
    };

    services.gpg-agent = {
      enable = true;
      pinentryFlavor = "curses";
    };
  };
}
