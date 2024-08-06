{ 
  lib, 
  fetchFromGitHub,
  mkPoetryApplication,
}:

mkPoetryApplication {
  pname = "gpt-cli";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "kharvd";
    repo = "gpt-cli";
    # rev = "v${version}"; 
    # Get this hash via:  nix-prefetch-url --unpack https://github.com/kharvd/gpt-cli/archive/refs/tags/v0.2.0.tar.gz
    sha256 = "015796zbcvqvmp6qjpd9l1xchkm51gak6pv4npcwb3ikrcfjgrqy"; 
  };

  # nativeBuildInputs = with python311Packages; [
  #   setuptools
  #   wheel
  #   build
  #   pip
  # ];

  # propagatedBuildInputs = with python311Packages; [
    # Add any runtime dependencies here, e.g., click, openai, etc.
  # ];

  meta = with lib; {
    description = "A CLI tool for interacting with GPT models";
    homepage = "https://github.com/kharvd/gpt-cli";
    license = licenses.mit;
    maintainers = [];
  };
}
