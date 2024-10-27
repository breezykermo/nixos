{ pkgs, ... }:
{
	home.packages = with pkgs; [
    libreoffice

		# CSV management in terminal
		csvkit
		visidata 

    # PDF
    qpdf

  ];
}
