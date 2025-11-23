{pkgs, ...}:
{
  home.packages = [
    # TR-100 Machine Report - system info display utility
    (pkgs.stdenv.mkDerivation {
      name = "usgc-machine-report";
      version = "1.0.0";

      src = pkgs.fetchFromGitHub {
        owner = "usgraphics";
        repo = "usgc-machine-report";
        rev = "master";
        sha256 = "sha256-0XX7FIAMdp5rEbvsu4+09a19g0kkM4v6Y5ynudpbQlI=";
      };

      buildInputs = [ pkgs.util-linux ];

      installPhase = ''
        mkdir -p $out/bin
        cp machine_report.sh $out/bin/machine-report
        chmod +x $out/bin/machine-report
      '';

      meta = with pkgs.lib; {
        description = "TR-100 Machine Report - system information display utility";
        homepage = "https://github.com/usgraphics/usgc-machine-report";
        license = licenses.bsd3;
      };
    })
  ];
}
