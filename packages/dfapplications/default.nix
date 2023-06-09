{
  stdenv,
  lib,
  fetchFromGitLab,
  meson,
  pkg-config,
  cmake,
  ninja,
  qtbase,
  wayland,
  dfipc,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dfapplications";
  version = "unstable-2023-02-09";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "applications";
    rev = "be3e1b24f420f58deac0f2ddbe1d081c3e4c6c6f";
    hash = "sha256-hyPdlFXEP0Di2KdRQF3HoIWzQIb120U5Kha5cz0pXew=";
  };

  nativeBuildInputs = [
    meson
    pkg-config
    ninja
  ];

  buildInputs = [
    qtbase
  ];

  propagatedBuildInputs = [
    dfipc
  ];

  dontWrapQtApps = true;

  meta = with lib; {
    homepage = "https://gitlab.com/desktop-frameworks/applications";
    maintainers = with maintainers; [shawn8901];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
