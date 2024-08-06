{ 
  lib, 
  buildPythonPackage,
  python311Packages,
  fetchFromGitHub,
  fetchPypi,
}:
let 
  openai = buildPythonPackage rec {
    pname = "openai";
    version = "1.30.2";
    format = "pyproject";
    src = fetchPypi {
      inherit pname version;
      # Get this hash via: nix-prefetch-url https://files.pythonhosted.org/packages/source/o/openai/openai-1.30.2.tar.gz
      sha256 = "1c7j792i4fl5bjywmvz5zfn20ksnynvxk4wr73x61ph50ps80rzq";
    };
  };
in
buildPythonPackage rec {
  pname = "gpt-cli";
  version = "0.2.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "kharvd";
    repo = "gpt-cli";
    rev = "v${version}"; 
    # Get this hash via:  nix-prefetch-url --unpack https://github.com/kharvd/gpt-cli/archive/refs/tags/v0.2.0.tar.gz
    sha256 = "015796zbcvqvmp6qjpd9l1xchkm51gak6pv4npcwb3ikrcfjgrqy"; 
  };

  nativeBuildInputs = with python311Packages; [
    setuptools
    wheel
    pip
  ];

  propagatedBuildInputs = [
    openai
    # "anthropic==0.25.9",
    # "attrs==23.2.0",
    # "black==24.4.2",
    # "cohere==5.5.3",
    # "google-generativeai==0.5.4",
    # "mistralai==0.1.8",
    # "prompt-toolkit==3.0.43",
    # "pytest==7.3.1",
    # "PyYAML==6.0.1",
    # "rich==13.7.1",
    # "typing_extensions==4.11.0",
  ];

  meta = with lib; {
    description = "A CLI tool for interacting with GPT models";
    homepage = "https://github.com/kharvd/gpt-cli";
    license = licenses.mit;
    maintainers = [];
  };
}
