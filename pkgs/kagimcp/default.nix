{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  fastmcp,
  pydantic,
  python-dateutil,
  typing-extensions,
  urllib3,
}:

buildPythonPackage rec {
  pname = "kagimcp";
  version = "1.0.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Yq7NM0OL17r9O0/Xv1JBCeqr/Vn9Zti1EFvdjmKbapw=";
  };

  build-system = [ hatchling ];

  dependencies = [
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
