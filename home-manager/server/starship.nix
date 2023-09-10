{
  config,
  ...
}: {
  programs.starship = {
    enable = true;

    settings = {
      battery.disabled = true;

      command_timeout = 10000;

      character = let
        character =
          if config.home.username == "root"
          then "#"
          else "\\$";
      in {
        success_symbol = "[${character}](bold green)";
        vicmd_symbol = "[${character}](bold yellow)";
        error_symbol = "[${character}](bold red)";
      };
      continuation_prompt = "[-](bright-black) ";

      directory.read_only = " 󰌾 "; # mdi

      shlvl = {
        disabled = false;
        symbol = "󰽘 "; # mdi
        threshold = 3;
      };

      package.symbol = "󰏗 "; # mdi

      jobs.symbol = "+";

      git_metrics.disabled = false;
      git_status = {
        ahead = "↑\${count}";
        behind = "↓\${count}";
        diverged = "⇕↑\${ahead_count}↓\${behind_count}";
        stashed = "S\${count}";
        modified = "~\${count}";
        renamed = "→\${count}";
        deleted = "D\${count}";
      };
      git_branch.symbol = "󰘬 "; # mdi
      git_commit.tag_symbol = "󰓹 "; # mdi

      status = {
        disabled = false;
        format = "[$status]($style) ";
        pipestatus = true;
        pipestatus_format = "$pipestatus";
        pipestatus_separator = "| ";
      };

      hostname.ssh_symbol = "󰩠 "; # mdi

      # ======== Languages ======== #
      aws.symbol = " "; # devicon
      azure.symbol = " "; # devicon
      # buf.symbol = "";
      c.symbol = " "; # devicon
      # cmake.symbol = "";
      # cobol.symbol = "";
      # conda.symbol = "";
      container.symbol = " "; # devicon
      crystal.symbol = " "; # devicon
      # dart.symbol = " ";
      deno.symbol = " "; # devicon
      docker_context.symbol = " "; # devicon
      dotnet.symbol = " "; # devicon
      elixir.symbol = " "; # devicon
      elm.symbol = " "; # devicon
      erlang.symbol = " "; # devicon
      gcloud.symbol = " "; # devicon
      golang.symbol = " "; # devicon
      haskell.symbol = " "; # devicon
      # helm.symbol = "";
      java.symbol = " "; # devicon
      # julia.symbol = "";
      kotlin.symbol = " "; # devicon
      kubernetes.symbol = " "; # devicon
      lua.symbol = " "; # devicon
      # memory_usage.symbol = "";
      # hg_branch = "";
      # nim.symbol = "";
      nix_shell.symbol = " "; # devicon
      nodejs.symbol = " "; # devicon
      ocaml.symbol = " "; # devicon
      # openstack.symbol = "";
      # package.symbol = "";
      perl.symbol = " "; # devicon
      php.symbol = " "; # devicon
      # pulumi.symbol = "";
      # purescript.symbol = "";
      python.symbol = " "; # devicon
      rlang.symbol = " "; # devicon
      # red.symbol = "";
      ruby.symbol = " "; # devicon
      rust.symbol = " "; # devicon
      scala.symbol = " "; # devicon
      # singularity.symbol = "";
      # spack.symbol = "";
      swift.symbol = " "; # devicon
      # terraform.symbol = "";
      vagrant.symbol = " "; # devicon
      # vlang.symbol = "";
      # vcsh.symbol = "";
      zig.symbol = " "; # devicon
    };
  };
}
