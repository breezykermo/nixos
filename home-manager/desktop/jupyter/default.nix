{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python311 
    python311Packages.jupyterlab
    python311Packages.pandas
    python311Packages.ipykernel
  ];
}
