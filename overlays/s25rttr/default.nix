{ stdenv
, lib
, fetchFromGitHub
, git
, cmake
, pkg-config
, boost
, bzip2
, curl
, gettext
, libiconv
, miniupnpc
, SDL2
, SDL2_mixer
, libsamplerate
}:

stdenv.mkDerivation rec {
  pname = "s25rttr";
  version = "0.9.5";

  message = ''
    Copy the S2 folder of the Settler 2 Gold Edition to ~/.s25rttr/S2/".
  '';

  src = fetchFromGitHub {
    owner = "Return-To-The-Roots";
    repo = "s25client";
    rev = "v${version}";
    fetchSubmodules = true;
    leaveDotGit = true;
    sha256 = "sha256-+89F6LtY6nEJEgVM1R5qiPhG6CLEKymowzEowuLCfUM=";
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

  patches = [ ./skip_placeholder.patch ];

  cmakeBuildType = "Release";

  cmakeFlags = [
    "-DRTTR_VERSION=${version}"
    "-DRTTR_USE_SYSTEM_LIBS=ON"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DRTTR_INSTALL_PLACEHOLDER=OFF"
    "-DRTTR_GAMEDIR=~/.s25rttr/S2/"
  ];

  meta = with lib; {
    description = "Return To The Roots (Settlers II(R) Clone) ";
    homepage = "https://www.rttr.info/";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ shawn8901 ];
  };
}
