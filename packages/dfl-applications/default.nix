{ stdenv, lib, fetchFromGitLab, meson, pkg-config, cmake, ninja, qt6, wayland
, dfl-ipc }:
stdenv.mkDerivation (finalAttrs: {
  pname = "dfl-applications";
  version = "0.2.0";

  src = fetchFromGitLab {
    owner = "desktop-frameworks";
    repo = "applications";
    rev = "v${finalAttrs.version}";
    hash = "sha256-I6W37tThshlL79lmMipJqynXsfjFRw6WzLPPw0dvqH4=";
  };

  nativeBuildInputs = [ meson pkg-config ninja qt6.qttools ];

  buildInputs = [ qt6.qtbase dfl-ipc ];

  propagatedBuildInputs = [ dfl-ipc ];

  mesonBuildType = "release";

  mesonFlags = [ (lib.mesonOption "use_qt_version" "qt6") ];

  dontWrapQtApps = true;

  outputs = [ "out" "dev" ];

  meta = with lib; {
    homepage = "https://gitlab.com/desktop-frameworks/applications";
    maintainers = with maintainers; [ shawn8901 ];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
})
