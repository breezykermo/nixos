{
  config,
  pkgs,
  lib,
  machineVars,
  theme,
  ...
}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # disable greetingfish

      # Trigger bell on sudo password prompt for terminal notification
      set -x SUDO_PROMPT (printf '\a[sudo] password for %%u: ')

      # Set a valid fish theme to avoid theme errors on startup
      if functions -q fish_config
        fish_config theme choose default 2>/dev/null
      end

      # Syntax highlighting / pager colors from the active palette
      # (themes/default.nix). These are `set -g`, which outranks the universal
      # variables `fish_config theme choose` just wrote above, so this block has
      # to stay after it.
      set -g fish_color_normal "${theme.foreground}"
      set -g fish_color_command "${theme.colors.blue}"
      set -g fish_color_keyword "${theme.colors.purple}"
      set -g fish_color_quote "${theme.colors.yellow}"
      set -g fish_color_redirection "${theme.colors.aqua}"
      set -g fish_color_end "${theme.colors.orange}"
      set -g fish_color_error "${theme.colors.red}"
      set -g fish_color_param "${theme.colors.fg2}"
      set -g fish_color_option "${theme.colors.bright_blue}"
      set -g fish_color_comment "${theme.colors.gray}"
      set -g fish_color_selection --background=${theme.colors.bg2}
      set -g fish_color_search_match --background=${theme.colors.bg2}
      set -g fish_color_operator "${theme.colors.bright_purple}"
      set -g fish_color_escape "${theme.colors.bright_aqua}"
      set -g fish_color_autosuggestion "${theme.colors.fg4}"
      set -g fish_color_cancel "${theme.colors.red}"
      set -g fish_color_valid_path --underline
      set -g fish_color_cwd "${theme.colors.green}"
      set -g fish_color_cwd_root "${theme.colors.red}"
      set -g fish_color_user "${theme.colors.aqua}"
      set -g fish_color_host "${theme.colors.blue}"
      set -g fish_pager_color_progress "${theme.colors.fg4}"
      set -g fish_pager_color_prefix "${theme.colors.aqua}" --bold
      set -g fish_pager_color_completion "${theme.colors.fg2}"
      set -g fish_pager_color_description "${theme.colors.gray}"
      set -g fish_pager_color_selected_background --background=${theme.colors.bg2}

      # Important to ensure switching to fish_vi_key_bindings hasn't removed
      # anything important
      fish_default_key_bindings

      zoxide init fish | source

      # NPM packages go to home directory so as not to modify nix store
      fish_add_path ~/.npm-packages/bin

      # Rust binaries built by me
      fish_add_path $HOME/.cargo-target/release
      # Rust binaries installed
      fish_add_path $HOME/.cargo/bin

      fish_add_path $HOME/.npm-global/bin

      # Local binaries
      fish_add_path $HOME/.local/bin

      if command -q opam
        eval (opam env)
      end

      # Auto-add SSH keys to agent if defined for this machine
      ${lib.optionalString (machineVars.sshKeys != []) ''
        for key in ${lib.concatStringsSep " " machineVars.sshKeys}
          ssh-add ~/.ssh/$key 2>/dev/null
        end
      ''}
    '';

    functions = {
      brlist = ''
        set -l original (pwd)

        if test -d .beads
          br list
        else
          for d in (find . -type d -name .beads)
            cd $d/..

            echo "=== $PWD ==="
            br list

            cd $original
          end
        end
      '';

      jjfetch = ''
        set -l original (pwd)

        if test -d .jj
          jj git fetch && jj new -r "trunk()"
        else
          for d in (find . -type d -name .jj)
            cd $d/..

            echo "=== $PWD ==="
            jj git fetch && jj new -r "trunk()"

            cd $original
          end
        end
      '';
    };

    plugins = [
      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      }
    ];
  };
}
