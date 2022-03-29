{ stdenv, lib, fetchurl }:

stdenv.mkDerivation rec {
  pname = "proton-ge-custom";
  version = "GE-Proton7-10";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
    sha256 = "rpvWeYq7IZNcpg0VQTDpT3nX79YvK8MemO8dIj0j9UQ=";
  };

  buildCommand = ''
    mkdir -p $out
    tar -C $out --strip=1 -x -f $src
  '';
}
