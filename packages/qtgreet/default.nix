{ stdenv, lib, fetchFromGitLab, ninja, meson, pkg-config, libxkbcommon, qt6
, wayland, wlroots, dfl-applications, wayqt, dfl-login1, dfl-utils, mpv, pixman
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qtgreet";
  version = "2.0.1";

  src = fetchFromGitLab {
    owner = "marcusbritanicus";
    repo = "qtgreet";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Lm7OdB9/o7BltPusuxTIuPQ4w23rCIKugEsjGR5vgVg=";
  };

  nativeBuildInputs = [ meson pkg-config ninja ];

  buildInputs = [
    qt6.qtbase
    qt6.qttools
    wayqt
    wayland
    wlroots
    dfl-applications
    dfl-utils
    dfl-login1
    mpv
    pixman
  ];

  dontWrapQtApps = true;

  mesonFlags = [
    (lib.mesonOption "use_qt_version" "qt6")
    (lib.mesonBool "nodynpath" true)
  ];

  meta = with lib; {
    homepage = "https://gitlab.com/marcusbritanicus/QtGreet";
    description =
      "Qt based greeter for greetd, to be run under wayfire or similar wlr-based compositors";
    maintainers = with maintainers; [ shawn8901 ];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
