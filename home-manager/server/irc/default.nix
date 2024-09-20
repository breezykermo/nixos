{ config, pkgs, lib, ...}:
let
  myWeechat = pkgs.weechat.override {
    configure = { availablePlugins, ... }: {
      scripts = with pkgs.weechatScripts; [
        wee-slack  
      ];
    };
  };
in
{
  home.packages = [ myWeechat ];
}
