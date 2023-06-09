{
  stdenv,
  lib,
  fetchFromGitLab,
  meson,
  pkg-config,
  cmake,
  ninja,
  qtbase,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dfutils";
  version = "unstable-2023-01-23";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "utils";
    rev = "30575a0fd2e50f2b655009c7cbc4a946794973b4";
    hash = "sha256-D4ilgCktwa4SQUNPIxN2DYu5nat4gFdhCTVSNiROjLw=";
  };

  nativeBuildInputs = [
    meson
    pkg-config
    ninja
    cmake
  ];

  buildInputs = [
    qtbase
  ];

  dontWrapQtApps = true;

  meta = with lib; {
    homepage = "https://gitlab.com/desktop-frameworks/utils";
    description = "Some utilities for DFL";
    maintainers = with maintainers; [shawn8901];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
