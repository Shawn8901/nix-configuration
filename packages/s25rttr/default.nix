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
    Copy the S2 folder of the Settler 2 Gold Edition to /var/lib/s25rttr/S2/".
  '';

  src = fetchFromGitHub {
    owner = "Return-To-The-Roots";
    repo = "s25client";
    rev = "397f2b2315e997504d4958bfbdea0af815ce559a";
    fetchSubmodules = true;
    sha256 = "sha256-6gBvWYP08eoT2i8kco/3nXnTKwVa20DWtv6fLaoH07M=";
  };

  nativeBuildInputs = [ cmake pkg-config ];

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

  patches = [ ./cmake_file_placeholder.patch ];

  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DRTTR_VERSION=${version}"
    "-DRTTR_REVISION=${src.rev}"
    "-DRTTR_USE_SYSTEM_LIBS=ON"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DRTTR_INSTALL_PLACEHOLDER=OFF"
    "-DRTTR_GAMEDIR=/var/lib/s25rttr/S2/"
  ];

  meta = with lib; {
    description = "Return To The Roots (Settlers II(R) Clone)";
    homepage = "https://www.rttr.info/";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ shawn8901 ];
  };
}
