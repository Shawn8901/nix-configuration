{ lib
, buildPythonApplication
, fetchFromGitHub
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

  pythonImportsCheck = [ "pytr" ];

  passthru.updateScript = writeScript "update-pytr" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p curl jq common-updater-scripts

    version="$(curl -sL "https://api.github.com/repos/marzzzello/pytr/tags" | jq '.[0].name' --raw-output)"
    update-source-version pytr "$version"
  '';

  meta = with lib; {
    homepage = "https://github.com/marzzzello/pytr";
    description = "Use TradeRepublic in terminal and mass download all documents ";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ shawn8901 ];
  };
}
