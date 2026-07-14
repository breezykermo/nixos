{pkgs, ...}: {
  home.packages = with pkgs; [
    csvkit # csv management
    visidata
    pdftk # pdf
    qpdf
  ];
}
