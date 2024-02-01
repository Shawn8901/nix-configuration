{ lib, fetchFromGitHub, stdenv, fetchzip, }:
stdenv.mkDerivation (finalAttrs: {
  pname = "grafana-datasource";
  version = "0.6.0";

  src = fetchzip {
    url =
      "https://github.com/VictoriaMetrics/${finalAttrs.pname}/releases/download/v${finalAttrs.version}/victoriametrics-datasource-v${finalAttrs.version}.zip";
    hash = "sha256-02mmnTsjoyraodhO9Ote6mAr5kvFduxsmbux9VpEtjE=";
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
