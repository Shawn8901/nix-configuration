{ stdenv, lib, fetchurl }:

stdenv.mkDerivation rec {
  pname = "proton-ge-custom";
  version = "GE-Proton7-38";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
    sha256 = "sha256-d+ZOJujJZ6BJ1cLYnNd5m84dBXYK/MfyG9HvwFyitdE=";
  };

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  '';
}
