{ config, pkgs, lib, ...}:
let
  myWeechat = pkgs.weechat.override {
    configure = { availablePlugins, ... }: {
      scripts = with pkgs.weechatScripts; [
        wee-slack  
        # weechat-matrix
      ];
    };
  };
in
{
  # home.packages = [ myWeechat ];
}
