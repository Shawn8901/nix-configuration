{ stdenv }:

stdenv.mkDerivation rec {
  name = "nas_mount";
  version = "0.0.1-dev";
  src = ./nas;
  phases = "installPhase fixupPhase";
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/etc/config/
    cp ${src}/* $out/bin/

    chmod +x $out/bin/*
  '';
}
