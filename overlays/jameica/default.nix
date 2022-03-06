{ prev, lib, stdenv, makeDesktopItem, jre }:
let
  _version = "2.10.1";
  _build = "482";
  version = "${_version}-${_build}";
  name = "jameica-${version}";

  swtSystem =
    if stdenv.hostPlatform.system == "i686-linux" then "linux"
    else if stdenv.hostPlatform.system == "x86_64-linux" then "linux64"
    else if stdenv.hostPlatform.system == "x86_64-darwin" then "macos64"
    else throw "Unsupported system: ${stdenv.hostPlatform.system}";
  desktopItem = makeDesktopItem {
    name = "jameica";
    exec = "jameica";
    comment = "Free Runtime Environment for Java Applications.";
    desktopName = "Jameica";
    genericName = "Jameica";
    icon = "jameica";
    categories = [ "Office" ];
  };
in
prev.jameica.overrideAttrs (oldAttrs: rec {

  installPhase = ''
    mkdir -p $out/libexec $out/lib $out/bin $out/share/{applications,${name},java}/

    # copy libraries except SWT
    cp $(find lib -type f -iname '*.jar' | grep -ve 'swt/.*/swt.jar') $out/share/${name}/
    # copy platform-specific SWT
    cp lib/swt/${swtSystem}/swt.jar $out/share/${name}/

    install -Dm644 releases/${_version}-*/jameica/jameica.jar $out/share/java/
    install -Dm644 plugin.xml $out/share/java/
    install -Dm644 build/jameica-icon.png $out/share/pixmaps/jameica.png
    cp ${desktopItem}/share/applications/* $out/share/applications/

    makeWrapper ${jre}/bin/java $out/bin/jameica \
      --add-flags "-cp $out/share/java/jameica.jar:$out/share/${name}/* ${
        lib.optionalString stdenv.isDarwin ''-Xdock:name="Jameica" -XstartOnFirstThread''
      } de.willuhn.jameica.Main" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath oldAttrs.buildInputs} \
      --run "cd $out/share/java/"
  '';
})
