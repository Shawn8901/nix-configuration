{ lib, stdenv, fetchFromGitHub, substituteAll, glib, gettext, gnome, zip }:

stdenv.mkDerivation rec {
  pname = "gnome-shell-extension-alphabetical-app-grid";
  version = "19.0";

  src = fetchFromGitHub {
    owner = "stuarthayhurst";
    repo = "alphabetical-grid-extension";
    rev = "v${version}";
    sha256 = "sha256-RJODrFevnPlX+w4O+ripGUELaPTUdunmtyvYcqA7hPg=";
  };

  nativeBuildInputs = [ gettext glib zip ];

  makeFlags = [ "INSTALLBASE=$(out)/share/gnome-shell/extensions" ];

  postPatch = ''
    patchShebangs scripts/update-po.sh
  '';

  buildPhase = ''
    scripts/update-po.sh -a
    glib-compile-schemas schemas
  '';
  
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/AlphabeticalAppGrid@stuarthayhurst

    ls -alh
    cp -r extension.js lib metadata.json po prefs.js schemas ui $out/share/gnome-shell/extensions/AlphabeticalAppGrid@stuarthayhurst
    ls -alh $out/share/gnome-shell/extensions/AlphabeticalAppGrid@stuarthayhurst
    runHook postInstall
  '';


  passthru = {
    extensionUuid = "AlphabeticalAppGrid@stuarthayhurst";
  };

  meta = with lib; {
    description = "Restore the alphabetical ordering of the app grid, removed in GNOME 3.38";
    homepage = "https://github.com/stuarthayhurst/alphabetical-grid-extension";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
    platforms = gnome.gnome-shell.meta.platforms;
  };
}