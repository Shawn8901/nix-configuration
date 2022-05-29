{ stdenv, lib, fetchurl }:

stdenv.mkDerivation rec {
  pname = "proton-ge-custom";
  version = "GE-Proton7-19";

  src = fetchurl {
    url =
      "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
    sha256 = "sha256-UzWt9YTi6d5kqcRkQj4lrMDycW1C9er9x9VYLka33sk=";
  };

  buildCommand = ''
    mkdir -p $out
    tar -C $out --strip=1 -x -f $src
  '';
}
