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
  pname = "dfipc";
  version = "unstable-2023-01-23";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "ipc";
    rev = "1762393f1d77865b6fdc111d0dd1dceb4edb7d67";
    hash = "sha256-iafhHhwbZf72BAqRcqGEl6jWlwyfjCzLYvRFoeNITz8=";
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
    homepage = "https://gitlab.com/desktop-frameworks/ipc";
    description = "A very simple set of IPC classes for inter-process communication.";
    maintainers = with maintainers; [shawn8901];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
