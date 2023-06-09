{
  stdenv,
  lib,
  fetchFromGitLab,
  ninja,
  meson,
  pkg-config,
  wrapQtAppsHook,
  libxkbcommon,
  pixman,
  qtbase,
  qttools,
  wayqt,
  wayland,
  wlroots_0_16,
  dfapplications,
  dflogin1,
  dfutils,
}:
stdenv.mkDerivation {
  pname = "qtgreet";
  version = "unstable-2023-04-19";

  src = fetchFromGitLab {
    owner = "marcusbritanicus";
    repo = "qtgreet";
    rev = "b2c7e7c670b13180b2d99b3598ec85ce1b651750";
    hash = "sha256-VkQPha4qsOb3LbqfkYwXJfMo36zHWrJX3n/dxcVFRmo=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    dfapplications
    dflogin1
    dfutils
    libxkbcommon
    pixman
    qtbase
    qttools
    wayqt
    wayland
    wlroots_0_16
  ];

  mesonFlags = [
    "-Dnodynpath=true"
  ];

  meta = with lib; {
    homepage = "https://gitlab.com/marcusbritanicus/QtGreet";
    description = "Qt based greeter for greetd, to be run under wayfire or similar wlr-based compositors";
    maintainers = with maintainers; [shawn8901];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
}
