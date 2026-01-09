{ pkgs, ... }:
{
	home.packages = with pkgs; [
    libreoffice   # docs
		csvkit        # csv management
		visidata
		pdftk         # pdf
    qpdf
  ];
}
