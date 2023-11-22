{ stdenv, lib, fetchurl, writeScript, }:
stdenv.mkDerivation (finalAttrs: {
  name = "proton-ge-custom";
  version = "GE-Proton8-25";

  src = fetchurl {
    url =
      "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    sha256 = "sha256-s3FgsnqzbgBo9zqwmsDJNjI8+TTG827bFxzWQr184Yo=";
  };

  passthru.runUpdate = true;

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  '';

  meta = with lib; {
    description =
      "Compatibility tool for Steam Play based on Wine and additional components";
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ shawn8901 ];
  };
})
