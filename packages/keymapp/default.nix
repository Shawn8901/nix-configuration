

{ lib, stdenv, fetchurl, autoPatchelfHook, gdk-pixbuf, glib, gtk3, libgudev, libusb1, systemd, webkitgtk, wrapGAppsHook }:

stdenv.mkDerivation {
  pname = "keymapp";
  version = "1.0.4";

  src = fetchurl {
    url = "https://oryx.nyc3.cdn.digitaloceanspaces.com/keymapp/keymapp-1.0.4.tar.gz";
    hash = "sha256-ScGhXeDP2jTKgGHkSlt4xUNnWpisG0rlzkajrPp9r9U=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook wrapGAppsHook ];

  buildPhase = ''
    mkdir -p $out/bin
    cp keymapp $out/bin
  '';

  buildInputs = [ gdk-pixbuf glib gtk3 libgudev libusb1 systemd webkitgtk ];

  meta = {
    description = "A live visual reference and flashing tool for your ZSA keyboard";
    homepage = "https://www.zsa.io/flash/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "keymapp";
    maintainers = with lib.maintainers; [ shawn8901 ];
  };
}
