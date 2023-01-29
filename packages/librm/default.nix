{
  stdenv,
  lib,
  fetchFromGitLab,
  meson,
  pkg-config,
  cmake,
  ninja,
  glib,
  gdk-pixbuf,
  gettext,
  libsoup,
  speex,
  spandsp,
  json-glib,
  libsndfile,
  gupnp,
  libcapi,
  libxml2,
  libtiff,
  libxcrypt,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "librm";
  version = "2.2.3";

  src = fetchFromGitLab {
    owner = "tabos";
    repo = "librm";
    rev = "${finalAttrs.version}";
    sha256 = "sha256-44nUlDcAwb6jV+dOThgotCFa4MVGc5ZuKhjpprVWIK4=";
  };

  nativeBuildInputs = [meson cmake pkg-config ninja];

  buildInputs = [
    glib
    gdk-pixbuf
    gettext
    libsoup
    libxml2
    speex
    spandsp
    libtiff
    json-glib
    libsndfile
    gupnp
    libcapi
    libxcrypt
  ];

  outputs = ["out" "dev"];

  passthru.runUpdate = true;

  meta = {
    description = "Router Manager Library for FRITZ!Box Router";
    homepage = "https://gitlab.com/tabos/librm";
    license = lib.licenses.lgpl2;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [shawn8901];
  };
})
