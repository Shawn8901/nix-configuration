{ 
  stdenv, lib, fetchFromGitHub, requireFile,
  cmake, pkg-config,
  boost, bzip2, curl, gettext, libiconv, miniupnpc, SDL2, SDL2_mixer, libsamplerate
}:
let 
  gamefiles = import ./s2files.nix { inherit stdenv requireFile;  };
in
stdenv.mkDerivation rec {
  pname = "s25rttr";
  version = "0.9.5";

  src = fetchFromGitHub {
    owner = "Return-To-The-Roots";
    repo = "s25client";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "sha256-6gBvWYP08eoT2i8kco/3nXnTKwVa20DWtv6fLaoH07M";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
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

  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DRTTR_REVISION=${version}"
    "-DRTTR_USE_SYSTEM_LIBS=ON"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DRTTR_ENABLE_OPTIMIZATIONS=OFF"
  ];

  postInstall = ''
      ls -alh $out
      rm -rf $out/share/s25rttr/S2/
      ln -s "${gamefiles}" $out/share/s25rttr/S2
  '';
}
