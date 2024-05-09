{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  fetchpatch,
  writeScript,
  certifi,
  coloredlogs,
  ecdsa,
  packaging,
  pathvalidate,
  pygments,
  requests-futures,
  shtab,
  websockets,
}:
buildPythonApplication rec {
  pname = "pytr";
  version = "0.1.9";

  src = fetchFromGitHub {
    owner = "marzzzello";
    repo = "pytr";
    rev = version;
    hash = "sha256-AK7nrRvrJ5n9ngU2jmET2MC/6qP8FEMa9QIjFOWPX1A=";
  };

  propagatedBuildInputs = [
    certifi
    coloredlogs
    ecdsa
    packaging
    pathvalidate
    pygments
    requests-futures
    shtab
    websockets
  ];

  pythonImportsCheck = [ "pytr" ];

  passthru.runUpdate = true;

  meta = with lib; {
    homepage = "https://github.com/marzzzello/pytr";
    description = "Use TradeRepublic in terminal and mass download all documents ";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ shawn8901 ];
    mainProgram = "pytr";
  };
}
