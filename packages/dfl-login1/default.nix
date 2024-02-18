{ stdenv, lib, fetchFromGitLab, meson, pkg-config, cmake, ninja, qt6 }:
stdenv.mkDerivation (finalAttrs: {
  pname = "dfl-login1";
  version = "0.2.0";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "login1";
    rev = "v${finalAttrs.version}";
    hash = "sha256-3BiYN8CdRTvopQuEfpemfAM3pQ7DAlCvZepBEf7IXiU=";
  };

  nativeBuildInputs = [ meson pkg-config ninja cmake qt6.qttools ];

  buildInputs = [ qt6.qtbase ];

  dontWrapQtApps = true;

  mesonBuildType = "release";

  mesonFlags = [ (lib.mesonOption "use_qt_version" "qt6") ];

  outputs = [ "out" "dev" ];

  meta = with lib; {
    homepage = "https://gitlab.com/desktop-frameworks/utils";
    description = "Implementation of systemd/elogind for DFL";
    maintainers = with maintainers; [ shawn8901 ];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
