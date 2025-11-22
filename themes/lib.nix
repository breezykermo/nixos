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

  # Get contrasting foreground color (simple light/dark check)
  # Returns either light or dark color based on background luminance
  contrastColor = bgHex: lightHex: darkHex:
    let
      rgb = hexToRgb bgHex;
      # Simple luminance calculation
      luminance = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
    in
    if luminance > 128 then darkHex else lightHex;
}
