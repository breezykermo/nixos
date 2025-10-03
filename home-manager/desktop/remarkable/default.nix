# ReMarkable related software 
{ ... }:
{
  home.packages = with pkgs; [
    # NOTE: must purchase the source code, and link to it via:
    #   nix-store --add-fixed sha256 rcu-d2024.001q-source.tar.gz
    rcu
  ];
}
