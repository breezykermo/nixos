{
  pkgs,
  lib,
  pellucid,
  theme,
  ...
}:
# Declarative pi (pi.dev) config, kept standalone from default.nix for
# readability/review. Imported by ./default.nix's `imports`.
#
# Split by how pi treats each path:
#   - READ-ONLY resources (extensions/skills/prompts/themes, models.json): pi
#     only reads them, so they are home.file symlinks into the nix store (same
#     pattern as the pinned Claude skills in default.nix). Edit them in
#     ./pi/<dir> (or the piModels attrset below) here and rebuild — NOT in
#     ~/.pi/agent (that path is a read-only store symlink).
#   - READ-WRITE settings.json: pi persists /settings, /model, theme, and
#     changelog dismissal to it at runtime, so it must stay a mutable real file.
#     Managed defaults are jq-merged in on activation (mirrors the claudeGitHook
#     precedent in default.nix), not symlinked.
#
# NOT managed here (pure runtime state / secrets, stays machine-local in
# ~/.pi/agent): auth.json, models-store.json, sessions/.
let
  mix = theme.themeLib.mix;

  # Nix-managed pi defaults — single source of truth. Merged into the mutable
  # settings.json; these keys win, pi's runtime-only keys are preserved.
  piSettings = {
    # Selects piTheme below. pi resolves this against the theme's `name` field
    # (not its filename), so the two must stay in sync.
    theme = "system";
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-8";
    defaultThinkingLevel = "medium";
    # Packages pi auto-installs on startup if missing. See docs/packages.md;
    # entries here mirror what `pi install <spec>` would write. Sources land
    # under ~/.pi/agent/{npm,git}/ (runtime state, machine-local, NOT managed).
    #
    # Rejected during the 2026-07-31 audit and deliberately absent:
    #   - rpiv-todo, pi-beads-extension: duplicate/misname the br/jj/beads
    #     workflow that global-core.md pins as the source of truth. A
    #     first-party replacement is tracked as beads issue nixos-0eu.
    #   - pi-lens: auto-installs ~25 external linter/LSP binaries into
    #     ~/.pi-lens/{bin,tools}/ via npx/pip/GitHub-release curls, a
    #     direct violation of the NixOS "everything declarative" rule and
    #     redundant with the per-project devShell toolchains.
    #   - context-mode: runtime-installs better-sqlite3 via ambient npm,
    #     ships ~1.5 MB of minified bundles, Elastic-2.0-licensed, and its
    #     before-agent hook mutates systemPrompt in a way that collides
    #     with ponytail's prefix-cache preservation. A first-party
    #     context-preservation extension is tracked as beads issue
    #     nixos-wfp (see the description there for the workarounds required).
    #
    # @dietrichgebert/ponytail is gated on the `pellucid` toggle in
    # ./default.nix: the two prose regimes are mutually exclusive (see the
    # comment there), so pellucid=true drops the package and pellucid=false
    # (this machine's default) installs it.
    packages =
      [
        "npm:pi-web-access" # https://pi.dev/packages/pi-web-access
        # caveman is now VENDORED inside the falconry package
        # (extensions/caveman + skills/caveman), so the unpinned git source is
        # gone: `pi update` hard-resets a git clone and would destroy edits, and
        # a duplicate skill name would load non-deterministically. See aus-cvm-rn0.
        # Lets pi's built-in `anthropic` provider talk to a Claude Code OAuth
        # subscription instead of a metered API key. Only touches OAuth
        # requests: it rewrites the system prompt's pi-specific wording,
        # filters/aliases tools to the MCP-style names the OAuth endpoint
        # accepts (`web_search_exa` -> `mcp__exa_mcp__web_search_exa`), and
        # rewrites history so the naming stays consistent. API-key and
        # non-Anthropic paths are untouched.
        #
        # Accepted where the 2026-07-31 rejects were not: MIT, no runtime
        # installs outside pi's own npm dir, no ambient binaries, and it
        # amends the provider rather than replacing pi's transport. Caveats:
        #   - Anthropic's policy scopes Claude Code OAuth tokens to Claude
        #     Code; a third-party client is a grey area, so this rides on
        #     ~/.pi/agent/auth.json (machine-local, unmanaged) and can be
        #     dropped by deleting this line.
        #   - Its optional alias-override file lives at
        #     ~/.pi/agent/extensions/pi-claude-code-use.json, but that dir is
        #     a read-only store symlink here. Automatic derivation needs no
        #     file; to override, add the JSON under ./pi/extensions/.
        "npm:@benvargas/pi-claude-code-use" # https://github.com/ben-vargas/pi-packages/tree/main/packages/pi-claude-code-use
        # First-party br/jj enforcement package. Local absolute path: a
        # first-class source loaded in place (not copied), so in-place edits
        # are safe and `pi update` skips it. See ~/code/_konrad/falconry.
        "/home/lox/code/_konrad/falconry"
      ];
  };
  piSettingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON piSettings);

  # Nix-managed custom model providers (~/.pi/agent/models.json). pi only READS
  # this file (reloaded each time /model opens), so it fits the read-only
  # home.file symlink pattern. Local Ollama models live here; edit and rebuild.
  #
  # apiKey "ollama" is a placeholder Ollama ignores, but pi still requires a
  # value before models appear in /model. compat.supportsDeveloperRole/
  # supportsReasoningEffort=false suit Ollama's OpenAI-compatible server.
  piModels = {
    providers.ollama = {
      baseUrl = "http://localhost:11434/v1";
      api = "openai-completions";
      apiKey = "ollama";
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
      };
      models = [
        {
          id = "qwen3-coder:30b";
          name = "Qwen3 Coder 30B (Local)";
          input = ["text"];
          contextWindow = 262144;
          maxTokens = 32768;
        }
        {
          id = "qwen3.6:35b";
          name = "Qwen3.6 35B (Local)";
          reasoning = true;
          input = ["text"];
          contextWindow = 262144;
          maxTokens = 32768;
        }
        {
          id = "gpt-oss:120b";
          name = "GPT-OSS 120B (Local)";
          reasoning = true;
          input = ["text"];
          contextWindow = 131072;
          maxTokens = 32768;
        }
        {
          id = "MichelRosselli/GLM-4.5-Air:Q5_K_M";
          name = "GLM-4.5 Air (Local)";
          reasoning = true;
          input = ["text"];
          contextWindow = 131072;
          maxTokens = 32768;
        }
        {
          id = "deepseek-r1:latest";
          name = "DeepSeek R1 (Local)";
          reasoning = true;
          input = ["text"];
          contextWindow = 131072;
          maxTokens = 32768;
        }
      ];
    };
  };
  piModelsFile = pkgs.writeText "pi-models.json" (builtins.toJSON piModels);

  # pi TUI theme, generated from the active palette in themes/default.nix so pi
  # matches Ghostty, Neovim and Claude Code rather than pi's built-in `dark`.
  # pi discovers themes from ~/.pi/agent/themes/*.json and selects by the `name`
  # field, so this is called `system` (as tuicr's theme is, see
  # home-manager/server/editor/vcs/default.nix) and tracks whatever palette is
  # active without needing a rename.
  #
  # Unlike Claude Code's theme format there is no `base` to inherit from: pi
  # validates that all 51 required tokens are present, so every one is listed.
  # `vars` is skipped -- nix already interpolates the palette, so the hexes go
  # in directly. Docs: <pi store path>/packages/coding-agent/docs/themes.md.
  piTheme = {
    name = "system";
    colors = {
      # Core UI. `muted` is secondary text, `dim` tertiary; `text = ""` would
      # mean the terminal default, but the palette's own fg is more exact.
      accent = theme.colors.aqua;
      border = theme.colors.blue;
      borderAccent = theme.colors.aqua;
      borderMuted = theme.colors.bg3;
      success = theme.colors.green;
      error = theme.colors.red;
      warning = theme.colors.yellow;
      muted = theme.colors.fg3;
      dim = theme.colors.fg4;
      text = theme.foreground;
      thinkingText = theme.colors.fg3;

      # Backgrounds and message content.
      selectedBg = theme.colors.bg2;
      userMessageBg = theme.colors.bg1;
      userMessageText = theme.foreground;
      customMessageBg = mix theme.colors.purple theme.background 0.15;
      customMessageText = theme.foreground;
      customMessageLabel = theme.colors.purple;
      toolPendingBg = theme.colors.bg1;
      toolSuccessBg = mix theme.colors.green theme.background 0.12;
      toolErrorBg = mix theme.colors.red theme.background 0.12;
      toolTitle = theme.foreground;
      toolOutput = theme.colors.fg3;

      # Markdown rendering.
      mdHeading = theme.colors.yellow;
      mdLink = theme.colors.blue;
      mdLinkUrl = theme.colors.fg4;
      mdCode = theme.colors.aqua;
      mdCodeBlock = theme.colors.fg1;
      mdCodeBlockBorder = theme.colors.bg3;
      mdQuote = theme.colors.fg3;
      mdQuoteBorder = theme.colors.bg4;
      mdHr = theme.colors.bg3;
      mdListBullet = theme.colors.aqua;

      # Tool diffs. pi colors the text (not the background) here, so these are
      # the plain palette hues rather than the mixed washes delta/tuicr use.
      toolDiffAdded = theme.colors.green;
      toolDiffRemoved = theme.colors.red;
      toolDiffContext = theme.colors.fg3;

      # Syntax highlighting in code blocks.
      syntaxComment = theme.colors.fg4;
      syntaxKeyword = theme.colors.purple;
      syntaxFunction = theme.colors.blue;
      syntaxVariable = theme.colors.fg1;
      syntaxString = theme.colors.green;
      syntaxNumber = theme.colors.orange;
      syntaxType = theme.colors.aqua;
      syntaxOperator = theme.colors.bright_aqua;
      syntaxPunctuation = theme.colors.fg2;

      # Editor border per thinking level, subtle -> prominent.
      thinkingOff = theme.colors.bg3;
      thinkingMinimal = theme.colors.fg4;
      thinkingLow = theme.colors.blue;
      thinkingMedium = theme.colors.bright_blue;
      thinkingHigh = theme.colors.purple;
      thinkingXhigh = theme.colors.bright_purple;
      thinkingMax = theme.colors.bright_red;

      # Editor border while typing a `!` shell command.
      bashMode = theme.colors.bright_orange;
    };
    # Colors for `/export`'s HTML output; derived from userMessageBg if omitted.
    export = {
      pageBg = theme.background;
      cardBg = theme.colors.bg1;
      infoBg = mix theme.colors.yellow theme.background 0.15;
    };
  };
  piThemeFile = pkgs.writeText "system.json" (builtins.toJSON piTheme);

  # ~/.pi/agent/themes must be ONE directory, and pi only reads it, so the
  # static tree (./pi/themes) and the generated theme above are joined into a
  # single store path rather than symlinked in separately -- home.file cannot
  # add a child to a directory that is itself a read-only store symlink.
  piThemesDir = pkgs.runCommand "pi-themes" {} ''
    mkdir -p "$out"
    cp -r ${./pi/themes}/. "$out"/
    chmod -R u+w "$out"
    cp ${piThemeFile} "$out"/system.json
  '';

  # Idempotently merges piSettingsFile into ~/.pi/agent/settings.json.
  mergePiSettings = pkgs.writeShellApplication {
    name = "pi-merge-settings";
    runtimeInputs = with pkgs; [jq coreutils];
    # The jq filter intentionally lives in single quotes.
    excludeShellChecks = ["SC2016"];
    text = builtins.readFile ./hooks/merge-pi-settings.sh;
  };


in {
  home.file = {
    ".pi/agent/prompts".source = ./pi/prompts;
    ".pi/agent/extensions".source = ./pi/extensions;
    ".pi/agent/themes".source = piThemesDir;
    ".pi/agent/models.json".source = piModelsFile;
  };

  home.activation.piSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${mergePiSettings}/bin/pi-merge-settings "${piSettingsFile}"
  '';
}
