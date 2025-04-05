{ config, pkgs, lib, ...}:
let 
  remouse = pkgs.python311Packages.buildPythonPackage rec {
  pname = "remarkable-mouse";
  version = "7.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "Evidlo";
    repo = "remarkable_mouse";
    rev = "master";
    sha256 = "sha256-0X/7SIfSnlEL98fxJBAYrHAkRmdtymqA7xBmVoa5VIw=";
  };

  propagatedBuildInputs = with pkgs.python311Packages; [
    libevdev
    paramiko
    pynput
    screeninfo
    evdev
  ];

  nativeBuildInputs = [
    pkgs.linuxHeaders
  ];

  meta = with lib; {
    description = "Use your reMarkable as a graphics tablet";
    homepage = "https://github.com/Evidlo/remarkable_mouse";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
};
in
{
  home.packages = [
    remouse
  ];
}
