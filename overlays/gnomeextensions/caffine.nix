{ lib, stdenv, fetchFromGitHub, substituteAll, glib, gettext, gnome }:

stdenv.mkDerivation rec {
  pname = "gnome-shell-extension-caffine";
  version = "39";

  src = fetchFromGitHub {
    owner = "eonpatapon";
    repo = "gnome-shell-extension-caffeine";
    rev = "v${version}";
    sha256 = "sha256-8P1mY3V66Id2Ji6KuQwx93qF8Z+uHBxd2jCikhXYdWM=";
  };

  nativeBuildInputs = [ gettext glib ];

  makeFlags = [ "INSTALLBASE=$(out)/share/gnome-shell/extensions" ];

  passthru = {
    extensionUuid = "caffeine@patapon.info";
  };
  
  postPatch = ''
    patchShebangs update-locale.sh
  '';

  buildPhase = ''
    make build
  '';
  
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions
    cp -r "caffeine@patapon.info" $out/share/gnome-shell/extensions/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Disable screensaver and auto suspend";
    homepage = "https://github.com/eonpatapon/gnome-shell-extension-caffeine";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
    platforms = gnome.gnome-shell.meta.platforms;
  };
}