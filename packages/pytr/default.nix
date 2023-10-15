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
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "marzzzello";
    repo = pname;
    rev = version;
    sha256 = "sha256-u++ekTXk7FRU6wbmfGaDdm/EuYMElg2BEay1ZF/Fgj0=";
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

  patches = [
    # Originally: https://github.com/marzzzello/pytr/pull/43
    ./connect_id.patch
  ];

  pythonImportsCheck = ["pytr"];

  passthru.runUpdate = true;

  meta = with lib; {
    homepage = "https://github.com/marzzzello/pytr";
    description = "Use TradeRepublic in terminal and mass download all documents ";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [shawn8901];
    mainProgram = "pytr";
  };
}
