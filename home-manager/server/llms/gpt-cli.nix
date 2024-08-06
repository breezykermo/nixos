{ lib, buildPythonPackage, fetchPypi, python311Packages }:

buildPythonPackage rec {
  pname = "gpt-cli";
  version = "0.2.0"; 

  src = fetchPypi {
    inherit pname version;
    sha256 = "0x67491ba"; # Replace with the actual sha256 hash
  };

  propagatedBuildInputs = with python311Packages; [
    # Add any dependencies here, e.g., click, openai, etc.
  ];

  meta = with lib; {
    description = "A CLI tool for interacting with GPT models";
    homepage = "https://github.com/kharvd/gpt-cli";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
