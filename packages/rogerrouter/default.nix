{
  stdenv,
  lib,
  fetchFromGitLab,
  meson,
  cmake,
  pkg-config,
  ninja,
  desktop-file-utils,
  wrapGAppsHook,
  ghostscript,
  gettext,
  gtk3,
  glib-networking,
  libhandy,
  libsoup,
  librm,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "rogerrouter";
  version = "2.4.2";

  src = fetchFromGitLab {
    owner = "tabos";
    repo = "rogerrouter";
    rev = "${finalAttrs.version}";
    sha256 = "sha256-9Ct+7/MEK7ji/7WVkkTrjUW2DY2kBaLF9xriRIFKf2c=";
  };

  nativeBuildInputs = [
    meson
    pkg-config
    cmake
    ninja
    desktop-file-utils
    wrapGAppsHook
  ];

  buildInputs = [
    glib-networking
    gettext
    gtk3
    ghostscript
    libhandy
    librm
    libsoup
  ];

  passthru.runUpdate = true;

  meta = {
    description = "Roger Router is a utility to control and monitor AVM Fritz!Box Routers.";
    homepage = "https://tabos.org/projects/rogerrouter/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ shawn8901 ];
  };
})
