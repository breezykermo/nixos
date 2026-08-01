# PDF viewer
{theme, ...}: {
  programs.zathura = {
    enable = true;
    # Colors from the active palette (themes/default.nix). `recolor` is bound to
    # `i` in zathurarc: it swaps a document's own black-on-white for
    # recolor-{light,dark}color, i.e. this palette's background and foreground,
    # so PDFs stop flashbanging against the rest of the desktop.
    options = {
      default-bg = theme.background;
      default-fg = theme.foreground;
      statusbar-bg = theme.colors.bg1;
      statusbar-fg = theme.foreground;
      inputbar-bg = theme.colors.bg1;
      inputbar-fg = theme.foreground;
      notification-bg = theme.colors.bg1;
      notification-fg = theme.foreground;
      notification-error-bg = theme.colors.red;
      notification-error-fg = theme.background;
      notification-warning-bg = theme.colors.yellow;
      notification-warning-fg = theme.background;
      completion-bg = theme.colors.bg1;
      completion-fg = theme.foreground;
      completion-group-bg = theme.background;
      completion-group-fg = theme.colors.blue;
      completion-highlight-bg = theme.colors.bg2;
      completion-highlight-fg = theme.foreground;
      highlight-color = theme.colors.yellow;
      highlight-active-color = theme.colors.orange;
      index-bg = theme.background;
      index-fg = theme.foreground;
      index-active-bg = theme.colors.bg2;
      index-active-fg = theme.foreground;
      render-loading-bg = theme.background;
      render-loading-fg = theme.foreground;
      recolor-lightcolor = theme.background;
      recolor-darkcolor = theme.foreground;
      recolor-keephue = true;
    };
    extraConfig = builtins.readFile ./zathurarc;
  };
}
