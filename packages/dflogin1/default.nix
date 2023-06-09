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
  pname = "dflogin1";
  version = "unstable-2023-02-24";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "login1";
    rev = "2f8335a98c3052517235303441147a1db295b609";
    hash = "sha256-LGEyRKOAgc9wMdAxMJ4Q6Dl/a0ikyVW7f/LQte5gLJI=";
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
    description = "Implementation of systemd/elogind for DFL";
    maintainers = with maintainers; [shawn8901];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
