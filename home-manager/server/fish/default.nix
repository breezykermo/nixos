{
  config,
  pkgs,
  lib,
  machineVars,
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
