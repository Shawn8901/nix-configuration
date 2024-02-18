{ stdenv, lib, fetchFromGitLab, meson, pkg-config, cmake, ninja, qt6 }:
stdenv.mkDerivation (finalAttrs: {
  pname = "dfl-ipc";
  version = "0.2.0";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "ipc";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Dz9ilrA/w+LR7cG7JBykC6n32s00kPoUayQtXuTkdss=";
  };

  nativeBuildInputs = [ meson pkg-config ninja cmake qt6.qttools ];

  buildInputs = [ qt6.qtbase ];

  dontWrapQtApps = true;

  mesonBuildType = "release";

  mesonFlags = [ (lib.mesonOption "use_qt_version" "qt6") ];

  outputs = [ "out" "dev" ];

  meta = with lib; {
    homepage = "https://gitlab.com/desktop-frameworks/ipc";
    description =
      "A very simple set of IPC classes for inter-process communication.";
    maintainers = with maintainers; [ shawn8901 ];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
