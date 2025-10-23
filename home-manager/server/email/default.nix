{pkgs, ...}: {
  home.packages = with pkgs; [
    lynx          # text-based web browser for rendering HTML emails
    chafa         # terminal graphics, for displaying images inline
    poppler_utils # provides pdftotext for PDF conversion
  ];

  programs = {
    # email in the terminal
    # NOTE: app passwords are per device, generate new ones if using this config
    # TODO: [compose] format-flowed=true
    # as currently this is just in my local config.
    aerc = {
      enable = true;
      extraConfig = {
        ui = { sort = "-r date"; };
        filters = {
          # Render HTML to readable text
          "text/html" = "lynx -stdin -dump -width 100";

          # Show images inline as ANSI
          "image/*" = "chafa -";

          # Convert PDFs to text
          "application/pdf" = "pdftotext - -";

          # Fallback: open anything else externally
          "*/*" = "xdg-open";
        };
      };
    };
  };
}
