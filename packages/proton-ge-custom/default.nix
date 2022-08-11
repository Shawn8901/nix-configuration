{ stdenv, lib, fetchurl }:

stdenv.mkDerivation rec {
  pname = "proton-ge-custom";
  version = "GE-Proton7-29";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
    sha256 = "sha256-bmi3l8FXpoIdBAp8HisXJ1awNxNFzK+XiVwhBN/jOUY=";
  };

  buildCommand = ''
    mkdir -p $out
    tar -C $out --strip=1 -x -f $src
  '';
}
