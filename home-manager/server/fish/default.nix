{ config, pkgs, lib, ...}:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # disable greetingfish

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

      # Claude Code Router integration
      set -x ANTHROPIC_BASE_URL http://127.0.0.1:3456
      set -x ANTHROPIC_AUTH_TOKEN "router"  # Router handles auth
    '';

    plugins = [
      { name = "bass"; src = pkgs.fishPlugins.bass.src; }
    ];
  };
}

