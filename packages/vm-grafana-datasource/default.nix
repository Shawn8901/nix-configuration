{ lib, fetchFromGitHub, stdenv, fetchzip, }:
stdenv.mkDerivation (finalAttrs: {
  pname = "grafana-datasource";
  version = "0.5.0";

  src = fetchzip {
    url =
      "https://github.com/VictoriaMetrics/${finalAttrs.pname}/releases/download/v${finalAttrs.version}/victoriametrics-datasource-v${finalAttrs.version}.zip";
    hash = "sha256-sFqHY8O9V3nGbWhnpqeoSOw6QF4xOtQzrS+YgLp/Yd8=";
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
    license = licenses.agpl3;
    maintainers = with maintainers; [ shawn8901 ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
})
