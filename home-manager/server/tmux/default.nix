{
  config,
  pkgs,
  lib,
  theme,
  ...
}: let
  plugins = pkgs.tmuxPlugins;
  resurrectDirPath = "$HOME/.config/tmux/resurrect";

  # Tmux config with theme colors injected
  tmuxConfig = builtins.readFile ./tmux.conf;
  themedConfig = ''
    ${tmuxConfig}

    # Theme color overrides
    set -wg mode-style bg=${theme.colors.yellow},fg=${theme.foreground}
    setw -g clock-mode-colour ${theme.colors.yellow}
    set -g window-status-style fg=${theme.foreground},bg=default
    set -g window-status-current-style fg=${theme.colors.purple},bg=default

    # Pane borders with thin lines
    set -g pane-border-style fg=${theme.colors.bg3}
    set -g pane-active-border-style fg=${theme.colors.yellow}
    set -g pane-border-lines single

    set -g message-style fg=${theme.foreground},bg=default,bold
  '';
in {
  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    keyMode = "vi";
    extraConfig = themedConfig;
    plugins = with plugins; [
      {
        # https://github.com/tmux-plugins/tmux-resurrect
        # Manually persists tmux environment across system restarts.
        #   prefix + Ctrl-s - save
        #   prefix + Ctrl-r - restore
        #
        plugin = resurrect;
        # Restore Neovim sessionstmux
        # See https://discourse.nixos.org/t/how-to-get-tmux-resurrect-to-restore-neovim-sessions/30819/9 for more information.
        extraConfig = ''
          # I have tested this strategy to work with neovim but it is not enough to have
          # Session.vim at the root of the path from which the plugin is going to do the restore
          # it is important that for neovim to be saved to be restored from the path where Session.vim
          # exist for this flow to kick in. Which means that even if tmux-resurrect saved the path with
          # Session.vim in it but vim was not open at the time of the save of the sessions then when
          # tmux-resurrect restore the window with the path with Session.vim nothing will happen.
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-capture-pane-contents 'on'

          # This three lines are specific to NixOS and they are intended
          # to edit the tmux_resurrect_* files that are created when tmux
          # session is saved using the tmux-resurrect plugin. Without going
          # into too much details the strings that are saved for some applications
          # such as nvim, vim, man... when using NixOS, appimage, asdf-vm into the
          # tmux_resurrect_* files can't be parsed and restored. This addition
          # makes sure to fix the tmux_resurrect_* files so they can be parsed by
          # the tmux-resurrect plugin and successfully restored.
          set -g @resurrect-dir ${resurrectDirPath}
          set -g @resurrect-hook-post-save-all 'sed -i -E "s|(pane.*nvim\s*:)[^;]+;.*\s([^ ]+)$|\1nvim \2|" ${resurrectDirPath}/last'
        '';
      }
      # {
      #   plugin = vim-tmux-navigator;
      # }
      {
        # https://github.com/tmux-plugins/tmux-yank
        # Enables copying to system clipboard.
        plugin = yank;
      }
      # set -g @plugin 'tmux-plugins/tmux-cpu'
      {
        plugin = cpu;
        extraConfig = ''
          set -g status-right '#{cpu_bg_color} CPU: #{cpu_icon} #{cpu_percentage} | %a %h-%d %H:%M '

          # Allow normal clear line, for tmux navigator but not working there
          bind C-l send-keys 'C-l'
        '';
      }
      {
        # https://github.com/tmux-plugins/tmux-continuum
        # Continuous saving of tmux environment. Automatic restore when tmux is started.
        plugin = continuum;
        extraConfig = ''
         set -g @continuum-restore 'on'
         set -g @continuum-save-interval '15'
        '';
      }
    ];
  };
}
