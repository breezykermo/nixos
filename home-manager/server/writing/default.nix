{pkgs, inputs, system, lib, ...}:
{
  home.packages = with pkgs; [
    pandoc      # document processor
    tectonic    # LaTeX compilation
    pdfpc       # PDF presentation console
    evince      # PDF viewer

    # Wrap typst with required libraries (OpenSSL 3)
    (pkgs.symlinkJoin {
      name = "typst-wrapped";
      paths = [ inputs.typst.packages.${system}.default ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/typst \
          --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.openssl ]}"
      '';
    })

    # Bene - EPUB viewer 
    # inputs.bene.packages.${system}.default

    # Optional: full LaTeX distribution (fallback for tectonic limitations)
    # texlive.combined.scheme-medium
  ];

  home.shellAliases = {
    pdfpc = "pdfpc -Z 1000:1000"; # necessary due to using tiling window manager
  };

  xdg = {
    terminal-exec = {
      enable = true;
      settings.default = ["ghostty.desktop"];
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/epub+zip" = "bene.desktop";
        "application/pdf" = [
          "org.pwmt.zathura.desktop"
          "brave-browser.desktop"
        ];
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
  };
}
