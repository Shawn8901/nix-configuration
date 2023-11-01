{ stdenvNoCC }:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "nas_mount";
  version = "0.0.1";
  src = ./nas;
  phases = "installPhase fixupPhase";
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/etc/config/
    cp ${finalAttrs.src}/* $out/bin/

    chmod +x $out/bin/*
  '';
})
