{pkgs, lib, ...}:
{
  # Zulip terminal client
  #
  # MANUAL STEP REQUIRED: After deploy, edit each ~/.zuliprc-* file and add your API key.
  # Get your API key from: Zulip → Personal settings → Account & privacy → API key
  #
  # Usage: zulip fcl | cel | fog
  #
  home.packages = [
    pkgs.zulip-term
  ];

  # Create config files with correct permissions if they don't exist
  # MANUAL STEP REQUIRED: Add your API key to each file after deploy
  home.activation.createZulipConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    create_zuliprc() {
      local file="$1"
      local email="$2"
      local site="$3"
      if [ ! -f "$file" ]; then
        cat > "$file" << EOF
[api]
email=$email
key=YOUR_API_KEY
site=$site
EOF
        chmod 600 "$file"
      fi
    }

    create_zuliprc "$HOME/.zuliprc-fcl" "hi@ohrg.org" "https://freecomputinglab.zulipchat.com"
    create_zuliprc "$HOME/.zuliprc-cel" "lachiekermode@gmail.com" "https://cognitive-engineering-lab.zulipchat.com"
    create_zuliprc "$HOME/.zuliprc-fog" "lachlan_kermode@brown.edu" "https://software-fog.zulipchat.com"
  '';

  programs.fish.functions.zulip = ''
    if test (count $argv) -eq 0
      echo "Usage: zulip <server>"
      echo ""
      echo "Available servers:"
      echo "  fcl - Free Computing Lab (hi@ohrg.org)"
      echo "  cel - Cognitive Engineering Lab (lachiekermode@gmail.com)"
      echo "  fog - Software Fog (lachlan_kermode@brown.edu)"
      echo ""
      echo "NOTE: Add your API key to ~/.zuliprc-<server> before first use."
      echo "Get it from: Zulip → Personal settings → Account & privacy → API key"
      return 1
    end
    zulip-term -c ~/.zuliprc-$argv[1]
  '';
}
