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
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wayqt";
  version = "0.1.1";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "wayqt";
    rev = "v${finalAttrs.version}";
    hash = "sha256-PL8XMddOtHsxgT6maDXMDvbHp2oW8CsMeKVtIAlmq7w=";
  };

  nativeBuildInputs = [
    meson
    pkg-config
    cmake
    ninja
  ];

  buildInputs = [
    qtbase
    wayland
  ];

  dontWrapQtApps = true;

  meta = with lib; {
    homepage = "https://gitlab.com/desktop-frameworks/wayqt";
    description = "A Qt-based wrapper for various wayland protocols.";
    maintainers = with maintainers; [shawn8901];
    platforms = platforms.linux;
    license = licenses.mit;
  };
})
