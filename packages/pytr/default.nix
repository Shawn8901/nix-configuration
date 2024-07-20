{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  certifi,
  coloredlogs,
  ecdsa,
  packaging,
  pathvalidate,
  babel,
  pygments,
  requests-futures,
  shtab,
  websockets,
}:
buildPythonApplication rec {
  pname = "pytr";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "pytr-org";
    repo = "pytr";
    rev = version;
    hash = "sha256-0ekUpkuyT0TB2YQi7CUMwosLI2tR0owJE2XQBaiy8Iw=";
  };

  nativeBuildInputs = [ babel ];

  propagatedBuildInputs = [
    babel
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
