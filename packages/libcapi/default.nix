{
  stdenv,
  lib,
  fetchFromGitLab,
  meson,
  pkg-config,
  cmake,
  ninja,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libcapi";
  version = "3.2.3";

  src = fetchFromGitLab {
    owner = "tabos";
    repo = "libcapi";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-RuFIoAWHNS/xHAG0XZOLHQuoRlqWMa7S0hrQdVStWb4=";
  };

  nativeBuildInputs = [meson cmake pkg-config ninja];

  outputs = ["out" "dev"];

  passthru.runUpdate = true;

  meta = {
    description = "Modular libcapi20";
    homepage = "https://gitlab.com/tabos/libcapi";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [shawn8901];
  };
})
