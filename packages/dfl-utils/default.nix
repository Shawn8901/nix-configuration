{ stdenv, lib, fetchFromGitLab, meson, pkg-config, cmake, ninja, qt6 }:
stdenv.mkDerivation (finalAttrs: {
  pname = "dfl-utils";
  version = "0.2.0";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "utils";
    rev = "v${finalAttrs.version}";
    hash = "sha256-IxWYxQP9y51XbZAR+VOex/GYZblAWs8KmoaoFvU0rCY=";
  };

  nativeBuildInputs = [ meson pkg-config ninja cmake qt6.qttools ];

  buildInputs = [ qt6.qtbase ];

  mesonBuildType = "release";

  mesonFlags = [ (lib.mesonOption "use_qt_version" "qt6") ];

  dontWrapQtApps = true;

  outputs = [ "out" "dev" ];

  meta = with lib; {
    homepage = "https://gitlab.com/desktop-frameworks/utils";
    description = "Some utilities for DFL";
    maintainers = with maintainers; [ shawn8901 ];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
