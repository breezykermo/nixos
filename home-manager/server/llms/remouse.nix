{ 
  lib, 
  buildPythonPackage,
  python311Packages,
  fetchFromGitHub,
  fetchPypi,
}:
let 
  openai = buildPythonPackage rec {
    pname = "remarkable_mouse";
    version = "7.1.0";
    format = "pyproject";
    src = fetchPypi {
      inherit pname version;
      # Get this hash via: nix-prefetch-url https://files.pythonhosted.org/packages/source/o/openai/openai-1.30.2.tar.gz
      sha256 = "";
    };
  };
in
buildPythonPackage rec {
  pname = "remarkable-mouse";
  version = "7.1.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "Evidlo";
    repo = "remarkable_mouse";
    rev = "v${version}"; 
    # Get this hash via:  nix-prefetch-url --unpack https://github.com/kharvd/gpt-cli/archive/refs/tags/v0.2.0.tar.gz
    sha256 = ""; 
  };

  nativeBuildInputs = with python311Packages; [
    setuptools
    wheel
    pip
  ];

  propagatedBuildInputs = [
    remarkable_mouse
  ];

  meta = with lib; {
    description = "Remarkable as a wacom tablet";
    homepage = "https://github.com/Evidlo/remarkable_mouse";
    license = licenses.mit;
    maintainers = [];
  };
}
