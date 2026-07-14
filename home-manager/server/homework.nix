# Homework-only home configuration, gated as a whole on `config.custom.homework` (the
# home-side flag from home-manager/custom.nix). Consolidates the bits that used to be
# sprinkled through core.nix and llms/default.nix behind inline localProfile/isHomework
# checks. homework is the 128GB Strix Halo box that runs local models (see
# machines/homework/configuration.nix); framework/dellxps get none of this.
#
# Imported UNCONDITIONALLY from home-manager/server/default.nix — the `lib.mkIf` below
# does the gating. (home-manager imports can't depend on `config`, so the gate lives here,
# matching how home-manager/desktop/obs etc. self-gate after nixos-fma.2.)
{ config, pkgs, lib, inputs, system, ... }:
let
  # claude-code-router v3 ships a proper npm layout: bin/ccr is a wrapper that execs the
  # real dist/main/cli.js, so no cli-fix hack is needed. Exposes an Anthropic-compatible
  # endpoint backed by the local ollama OpenAI-compatible API; invoke with `ccr code` and
  # pick a model in-session with `/model ollama,<name>` (see `allmodels`).
  claude-code-router = inputs.llm-agents.packages.${system}.claude-code-router;

  ccrConfig = {
    LOG = false;
    # Claude Code's global `effortLevel` setting makes it send a `reasoning_effort`
    # field on every request. Ollama's /v1/chat/completions rejects this for
    # qwen3-coder:30b (no thinking mode); this transformer strips reasoning/thinking
    # fields before they reach Ollama.
    # https://github.com/musistudio/claude-code-router/issues/972
    transformers = [
      { path = "${config.home.homeDirectory}/.claude-code-router/transformers/strip-reasoning-params.js"; }
    ];
    Providers = [
      {
        name = "ollama";
        api_base_url = "http://localhost:11434/v1/chat/completions";
        api_key = "ollama"; # ollama ignores the key, but CCR requires the field
        models = [
          "qwen3-coder:30b"
          "gpt-oss:120b"
          "MichelRosselli/GLM-4.5-Air:Q5_K_M"
        ];
        transformer = {
          "qwen3-coder:30b" = {
            use = [ "strip-reasoning-params" ];
          };
        };
      }
    ];
    Router = {
      default = "ollama,qwen3-coder:30b";     # agentic workhorse with reliable tool calls
      background = "ollama,qwen3-coder:30b";   # cheap/fast side tasks
      think = "ollama,gpt-oss:120b";           # heavier reasoning
      longContext = "ollama,gpt-oss:120b";
      longContextThreshold = 24000;
    };
  };
in
{
  config = lib.mkIf config.custom.homework {
    home.file = {
      ".claude-code-router/config.json".text = builtins.toJSON ccrConfig;
      ".claude-code-router/transformers/strip-reasoning-params.js".source = ./llms/transformers/strip-reasoning-params.js;
      ".config/zai-models.json".text = builtins.toJSON {
        models = [
          "GLM-5.2"
          "GLM-5.1"
          "GLM-5"
          "GLM-5-Turbo"
          "GLM-4.7"
          "GLM-4.6"
          "GLM-4.5"
          "GLM-4.5-Air"
          "GLM-5V-Turbo"
          "GLM-4.6V"
        ];
      };
    };

    programs.fish.functions = {
      # `claude` runs the real binary unmodified, against your Claude Pro/Max
      # subscription login.
      claude = ''
        command claude $argv
      '';

      # Lists "provider,model" strings usable with `/model` inside `ccr code`.
      # Shows both ollama models (from config) and z.ai models (from config file).
      allmodels = ''
        echo "# Ollama models (via ccr code):"
        jq -r '.Providers[] | select(.name == "ollama") | .name as $p | .models[] | "\($p),\(.)"' ~/.claude-code-router/config.json 2>/dev/null || echo "# No ollama config found"
        echo ""
        echo "# z.ai models (via glm wrapper):"
        jq -r '.models[] | "zai,\(.)"' ~/.config/zai-models.json 2>/dev/null || echo "# No z.ai models config found"
      '';
    };

    home.packages = [
      claude-code-router
    ] ++ (with pkgs; [
      nvtopPackages.amd  # GPU TUI; reads amdgpu sysfs (works on gfx1151 where amdsmi is blind)
    ]);

    home.sessionVariables = {
      # Where ollama stores models (see machines/homework). Set here so it's exported to
      # fish, tmux panes, and non-interactive contexts alike.
      OLLAMA_MODELS = "${config.home.homeDirectory}/data/ollama/models";
    };

    # gfx1151's monitoring isn't readable via amdsmi/rocm-smi, so btop's GPU panel may
    # show N/A for utilization (nvtop above is the reliable one) — but rocmSupport still
    # pulls rocm-smi + recompiles btop. Keep it homework-only.
    programs.btop.package = pkgs.btop.override { rocmSupport = true; };
  };
}
