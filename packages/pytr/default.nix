{ lib
, buildPythonApplication
, fetchFromGitHub
, fetchpatch
, writeScript
, certifi
, coloredlogs
, ecdsa
, packaging
, pathvalidate
, pygments
, requests-futures
, shtab
, websockets
,
}:
buildPythonApplication rec {
  pname = "pytr";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "marzzzello";
    repo = "pytr";
    rev = version;
    hash = "sha256-4NVjr77Go+sBS5RBf9r2GWtovODZFQN0cQ5RwmAI5iw=";
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
