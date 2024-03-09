{ stdenv, lib, fetchurl, writeScript, }:
stdenv.mkDerivation (finalAttrs: {
  name = "proton-ge-custom";
  version = "GE-Proton9-1";

  src = fetchurl {
    url =
      "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    sha256 = "sha256-wCIffeayOy3kEwmIKB7e+NrliuSpKXoVYC334fxVB3U=";
  };

  passthru.runUpdate = true;

  buildCommand = ''
    mkdir -p $out/{bin,opt}
    tar -C $out/opt --strip=1 -x -f $src

    ln -s $out/opt/toolmanifest.vdf $out/bin/toolmanifest.vdf
    install -Dm644 $out/opt/compatibilitytool.vdf $out/bin/compatibilitytool.vdf
    sed -i "s#\"install_path\" \".\"#\"install_path\" \"$out\/opt\/\"#g"  $out/bin/compatibilitytool.vdf
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
