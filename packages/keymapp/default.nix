

{ lib, stdenv, fetchurl, autoPatchelfHook, gdk-pixbuf, glib, gtk3, libgudev
, libusb1, systemd, webkitgtk, wrapGAppsHook, makeDesktopItem, copyDesktopItems
}:
let
  desktopItem = makeDesktopItem {
    name = "keymapp";
    icon = "keymapp";
    desktopName = "Keymapp";
    categories = [ "Settings" "HardwareSettings" ];
    type = "Application";
    exec = "keymapp";
  };
in stdenv.mkDerivation {
  pname = "keymapp";
  version = "1.0.4";

  src = fetchurl {
    url =
      "https://oryx.nyc3.cdn.digitaloceanspaces.com/keymapp/keymapp-1.0.4.tar.gz";
    hash = "sha256-ScGhXeDP2jTKgGHkSlt4xUNnWpisG0rlzkajrPp9r9U=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ copyDesktopItems autoPatchelfHook wrapGAppsHook ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $out/bin
    cp keymapp $out/bin

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 ${./keymapp.png} "$out/share/pixmaps/keymapp.png"
    runHook postInstall
  '';

  buildInputs = [ gdk-pixbuf glib gtk3 libgudev libusb1 systemd webkitgtk ];

  desktopItems = [ desktopItem ];

  meta = {
    description =
      "A live visual reference and flashing tool for your ZSA keyboard";
    homepage = "https://www.zsa.io/flash/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "keymapp";
    maintainers = with lib.maintainers; [ shawn8901 ];
  };
}
