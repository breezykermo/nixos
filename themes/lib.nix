{ lib }:

let
  # Helper to convert hex digit to decimal
  hexDigitToInt = d:
    if d == "0" then 0
    else if d == "1" then 1
    else if d == "2" then 2
    else if d == "3" then 3
    else if d == "4" then 4
    else if d == "5" then 5
    else if d == "6" then 6
    else if d == "7" then 7
    else if d == "8" then 8
    else if d == "9" then 9
    else if d == "a" || d == "A" then 10
    else if d == "b" || d == "B" then 11
    else if d == "c" || d == "C" then 12
    else if d == "d" || d == "D" then 13
    else if d == "e" || d == "E" then 14
    else if d == "f" || d == "F" then 15
    else 0;

  # Convert 2-digit hex to decimal
  hexPairToInt = hex:
    let
      d1 = builtins.substring 0 1 hex;
      d2 = builtins.substring 1 1 hex;
    in
    (hexDigitToInt d1) * 16 + (hexDigitToInt d2);

  # Convert hex color to RGB values
  # Example: hexToRgb "#ff0000" => { r = 255; g = 0; b = 0; }
  hexToRgb = hex:
    let
      # Remove # prefix if present
      cleanHex = lib.removePrefix "#" hex;
      # Extract components
      r = hexPairToInt (builtins.substring 0 2 cleanHex);
      g = hexPairToInt (builtins.substring 2 2 cleanHex);
      b = hexPairToInt (builtins.substring 4 2 cleanHex);
    in
    { inherit r g b; };
in
{
  inherit hexToRgb;

  # Convert hex to rgba string with optional alpha
  # Example: hexToRgba "#ff0000" 0.8 => "rgba(255, 0, 0, 0.8)"
  hexToRgba = hex: alpha:
    let
      rgb = hexToRgb hex;
    in
    "rgba(${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}, ${toString alpha})";

  # Convert hex to rgba hex format (for Hyprland)
  # Example: hexToRgbaHex "#ff0000" "aa" => "rgba(ff0000aa)"
  hexToRgbaHex = hex: alphaHex:
    let
      cleanHex = lib.removePrefix "#" hex;
    in
    "rgba(${cleanHex}${alphaHex})";

  # Convert hex to terminal color escape sequence
  # Example: hexToTermColor "#ff0000" => "\033[38;2;255;0;0m"
  hexToTermColor = hex:
    let
      rgb = hexToRgb hex;
    in
    "\\033[38;2;${toString rgb.r};${toString rgb.g};${toString rgb.b}m";

  # Apply opacity to hex color (returns hex)
  # This is a simplified version that just returns the hex as-is
  # since true color blending requires background color info
  withOpacity = hex: opacity: hex;

  # Blend two hex colors together
  # Example: mix "#ff0000" "#000000" 0.2 => 20% red, 80% black
  mix = hexA: hexB: ratio:
    let
      a = hexToRgb hexA;
      b = hexToRgb hexB;
      blend = ca: cb:
        let
          v = ca * ratio + cb * (1 - ratio);
          rounded = builtins.floor (v + 0.5);
        in
        if rounded > 255 then 255 else if rounded < 0 then 0 else rounded;
      toHexByte = n:
        let
          hexChars = "0123456789abcdef";
          hi = n / 16;
          lo = n - hi * 16;
        in
        (builtins.substring hi 1 hexChars) + (builtins.substring lo 1 hexChars);
    in
    "#" + toHexByte (blend a.r b.r) + toHexByte (blend a.g b.g) + toHexByte (blend a.b b.b);

  # Get contrasting foreground color (simple light/dark check)
  # Returns either light or dark color based on background luminance
  contrastColor = bgHex: lightHex: darkHex:
    let
      rgb = hexToRgb bgHex;
      # Simple luminance calculation
      luminance = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
    in
    if luminance > 128 then darkHex else lightHex;

  # Convert hex color to nearest 256-color terminal color code
  # Returns a string like "color223" or "default"
  # Uses known good mappings for common theme colors, with fallback to palette approximation
  hexTo256Color = hex:
    let
      # Normalize hex (remove # and convert to lowercase)
      cleanHex = lib.toLower (lib.removePrefix "#" hex);

      # Known good color mappings for common theme colors
      # These are manually verified to look good in terminals
      knownColors = {
        # Gruvbox colors
        "fb4934" = "color167";  # red
        "b8bb26" = "color142";  # green
        "fabd2f" = "color214";  # yellow
        "83a598" = "color109";  # blue (use 109 instead of 108)
        "d3869b" = "color175";  # purple
        "8ec07c" = "color108";  # aqua
        "fe8019" = "color208";  # orange
        "ebdbb2" = "color223";  # fg1
        "fbf1c7" = "color230";  # fg0
        "504945" = "color59";   # bg2
        "3c3836" = "color237";  # bg1
        # Catppuccin Mocha colors
        "f38ba8" = "color217";  # red
        "a6e3a1" = "color151";  # green
        "f9e2af" = "color223";  # yellow
        "89b4fa" = "color117";  # blue
        "cba6f7" = "color183";  # purple
        "94e2d5" = "color122";  # aqua
        "fab387" = "color215";  # orange
        "cdd6f4" = "color254";  # fg0
        "bac2de" = "color146";  # fg1
        "181825" = "color235";  # bg1
        "313244" = "color59";   # bg2
        "45475a" = "color241";  # bg3
        # Catppuccin Macchiato colors
        "ed8796" = "color210";  # red
        "a6da95" = "color151";  # green
        "eed49f" = "color223";  # yellow
        "8aadf4" = "color111";  # blue
        "c6a0f6" = "color177";  # purple
        "8bd5ca" = "color116";  # aqua
        "f5a97f" = "color215";  # orange
        "cad3f5" = "color254";  # fg0
        "b8c0e0" = "color146";  # fg1
        "1e2030" = "color235";  # bg1
        "363a4f" = "color59";   # bg2
        # Catppuccin Frappé colors
        "e78284" = "color210";  # red
        "a6d189" = "color142";  # green
        "e5c890" = "color222";  # yellow
        "8caaee" = "color110";  # blue
        "ca9ee6" = "color176";  # purple
        "81c8be" = "color115";  # aqua
        "ef9f76" = "color215";  # orange
        "c6d0f5" = "color254";  # fg0
        "b5bfe2" = "color153";  # fg1
        "292c3c" = "color235";  # bg1
        "414559" = "color59";   # bg2
      };

      # Check if we have a known mapping
      knownColor = knownColors.${cleanHex} or null;

      # If we have a known mapping, use it; otherwise compute it
    in
    if knownColor != null then knownColor
    else
      let
        rgb = hexToRgb hex;

        # Helper: max of two values
        max = a: b: if a > b then a else b;

        # Helper: min of two values
        min = a: b: if a < b then a else b;

        # Helper: absolute value
        abs = x: if x < 0 then -x else x;

        sq = x: x * x;

        # Find closest color in 256-color palette using proper color distance
        # The xterm 256-color palette has these value levels for RGB cube:
        # 0: 0, 1: 95, 2: 135, 3: 175, 4: 215, 5: 255
        colorValues = [0 95 135 175 215 255];

        # Convert RGB value to closest palette level (0-5)
        toColorLevel = val:
          let
            # Find closest value in colorValues
            distances = builtins.map (cv: abs (val - cv)) colorValues;
            minDist = builtins.foldl' min 256 distances;
            # Find index of minimum distance
            findIndex = lst: target: idx:
              if idx >= builtins.length lst then 0
              else if builtins.elemAt lst idx == target then idx
              else findIndex lst target (idx + 1);
          in
          findIndex distances minDist 0;

        # RGB cube candidate (colors 16-231): 16 + 36*r + 6*g + b
        rLevel = toColorLevel rgb.r;
        gLevel = toColorLevel rgb.g;
        bLevel = toColorLevel rgb.b;
        cubeR = builtins.elemAt colorValues rLevel;
        cubeG = builtins.elemAt colorValues gLevel;
        cubeB = builtins.elemAt colorValues bLevel;
        cubeIndex = 16 + 36 * rLevel + 6 * gLevel + bLevel;
        cubeDist = sq (rgb.r - cubeR) + sq (rgb.g - cubeG) + sq (rgb.b - cubeB);

        # Grayscale ramp candidate (colors 232-255): values 8, 18, 28, ..., 238
        avg = (rgb.r + rgb.g + rgb.b) / 3;
        grayStepRaw = builtins.floor ((avg - 8 + 5) / 10);
        grayStep = max 0 (min 23 grayStepRaw);
        grayVal = 8 + grayStep * 10;
        grayIndex = 232 + grayStep;
        grayDist = sq (rgb.r - grayVal) + sq (rgb.g - grayVal) + sq (rgb.b - grayVal);

        # Pick whichever candidate is actually closer in RGB space, rather than
        # guessing from a "looks grayish" threshold (which misclassifies colors
        # like dark blue-grays into the wrong, much-less-accurate cube cell).
        colorIndex = if grayDist < cubeDist then grayIndex else cubeIndex;
      in
      "color${toString colorIndex}";
}
