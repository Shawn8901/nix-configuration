{ stdenv, lib, fetchFromGitLab, substituteAll, meson, pkg-config, qt6, ninja
, wayland }:

stdenv.mkDerivation (finalAttrs: {
  pname = "wayqt";
  version = "0.2.0";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "wayqt";
    rev = "v${finalAttrs.version}";
    hash = "sha256-qlRRkqhKlcsd9lzlqfE0V0gjudELyENu4IH1NfO/+pI=";
  };

  patches = [
    # qmake get qtbase's path, but wayqt need qtwayland
    (substituteAll {
      src = ./fix-qtwayland-header-path.diff;
      qtWaylandPath = "${qt6.qtwayland}/include";
    })
  ];

  nativeBuildInputs = [ meson pkg-config qt6.qttools ninja ];

  buildInputs = [ qt6.qtbase qt6.qtwayland wayland ];

  mesonFlags = [ "-Duse_qt_version=qt6" ];

  dontWrapQtApps = true;

  outputs = [ "out" "dev" ];

  meta = {
    homepage = "https://gitlab.com/desktop-frameworks/wayqt";
    description =
      "Qt-based library to handle Wayland and Wlroots protocols to be used with any Qt project";
    maintainers = with lib.maintainers; [ rewine ];
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
  };
})
