{ stdenv, lib, fetchurl, nix-update-script }:

stdenv.mkDerivation (finalAttrs: {
  name = "proton-ge-custom";
  version = "GE-Proton7-43";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    sha256 = "sha256-owpe+spCfRY9H7yPqgbCIcnEOgNTtSeeEehTDsZNjQw=";
  };

  passthru.updateScript = ./update.sh;

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  '';
})
