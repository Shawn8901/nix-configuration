{ lib
, fetchFromGitHub
, stdenv
, fetchzip
,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "grafana-datasource";
  version = "0.8.3";

  src = fetchzip {
    url = "https://github.com/VictoriaMetrics/${finalAttrs.pname}/releases/download/v${finalAttrs.version}/victoriametrics-datasource-v${finalAttrs.version}.zip";
    hash = "sha256-EfWcR0YsQr8JUV79IaWr84M+DqlkKFlJDaMIfDTdXuE=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    cp -r $src $out
    runHook postInstall
  '';

  passthru.runUpdate = true;

  meta = with lib; {
    homepage = "https://github.com/VictoriaMetrics/grafana-datasource";
    description = "Grafana Plugin for VictoriaMetrics";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ shawn8901 ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
