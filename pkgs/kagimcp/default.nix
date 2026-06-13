{
  lib,
  buildPythonPackage,
  fetchPypi,
  fastmcp,
  pydantic,
  python-dateutil,
  typing-extensions,
  urllib3,
}:

buildPythonPackage rec {
  pname = "kagimcp";
  version = "1.0.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-173akdi8xpav22sxhrpxb7yspsh9859bzmsg7gyvmmwb8crwvbk2";
  };

  propagatedBuildInputs = [
    fastmcp
    pydantic
    python-dateutil
    typing-extensions
    urllib3
  ];

  pythonImportsCheck = [ "kagimcp" ];

  meta = with lib; {
    description = "Kagi MCP server for Model Context Protocol integration";
    homepage = "https://github.com/kagisearch/kagimcp";
    license = licenses.unfree; # Kagi API requires subscription
    maintainers = [ ];
  };
}
