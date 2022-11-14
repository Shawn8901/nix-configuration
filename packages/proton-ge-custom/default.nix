{ stdenv, lib, fetchurl, nix-update-script }:

stdenv.mkDerivation (finalAttrs: {
  name = "proton-ge-custom";
  version = "GE-Proton7-41";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    sha256 = "sha256-EPV1d7X5KYV2wZWOzW1JujxBSopvuzwIoY1+mXoswVU=";
  };

  passthru.updateScript = ./update.sh;

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  '';
})
