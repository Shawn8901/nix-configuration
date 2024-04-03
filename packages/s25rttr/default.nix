{
  stdenv,
  lib,
  fetchFromGitHub,
  git,
  cmake,
  pkg-config,
  boost,
  bzip2,
  curl,
  gettext,
  libiconv,
  miniupnpc,
  SDL2,
  SDL2_mixer,
  libsamplerate,
  writeScript,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "s25rttr";
  version = "0.9.5";

  message = ''
    Copy the S2 folder of the Settler 2 Gold Edition to /var/lib/s25rttr/S2/".
  '';

  src = fetchFromGitHub {
    owner = "Return-To-The-Roots";
    repo = "s25client";
    rev = "v${finalAttrs.version}";
    fetchSubmodules = true;
    sha256 = "sha256-6gBvWYP08eoT2i8kco/3nXnTKwVa20DWtv6fLaoH07M=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    git
    boost
    bzip2
    curl
    gettext
    libiconv
    miniupnpc
    SDL2
    SDL2_mixer
    libsamplerate
  ];

  env.NIX_CFLAGS_COMPILE = toString [ "-Wno-error=deprecated-declarations" ];

  patches = [ ./cmake_file_placeholder.patch ];

  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DRTTR_VERSION=${finalAttrs.version}"
    "-DRTTR_REVISION=${finalAttrs.src.rev}"
    "-DRTTR_USE_SYSTEM_LIBS=ON"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DRTTR_INSTALL_PLACEHOLDER=OFF"
    "-DRTTR_GAMEDIR=/var/lib/s25rttr/S2/"
  ];

  passthru.runUpdate = true;
  passthru.updateScript = writeScript "update-s25rttr" ''
    #!/usr/bin/env nix-shell
    #!nix-shell -i bash -p curl jq common-updater-scripts

    version="$(curl -sL "https://api.github.com/repos/Return-To-The-Roots/s25client/releases" | jq 'map(select(.prerelease == false)) | .[0].tag_name | .[1:]' --raw-output)"
    update-source-version s25rttr "$version"
  '';

  meta = {
    description = "Return To The Roots (Settlers II(R) Clone)";
    homepage = "https://www.rttr.info/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ shawn8901 ];
  };
})
