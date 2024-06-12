{ pkgs, lib, ...}:
{
	services.ollama.enable = true;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      #defaultNetwork.settings.dns_enabled = true;
    };
 
    oci-containers = {
      backend = "podman";
 
      containers = {
        open-webui = import ./containers/open-webui.nix;
      };
    };
  };
}
