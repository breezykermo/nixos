{ config, pkgs, lib, ...}:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # disable greetingfish

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

      if command -q opam
        eval (opam env)
      end

      # Set Ollama models directory (for homework machine)
      set -x OLLAMA_MODELS $HOME/data/ollama/models
    '';

    plugins = [
      { name = "bass"; src = pkgs.fishPlugins.bass.src; }
    ];
  };
}

