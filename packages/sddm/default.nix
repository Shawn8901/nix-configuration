{
  mkDerivation,
  lib,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  extra-cmake-modules,
  pkg-config,
  libxcb,
  libpthreadstubs,
  libXdmcp,
  libXau,
  qtbase,
  qtdeclarative,
  qtquickcontrols2,
  qttools,
  pam,
  systemd,
}:
mkDerivation {
  pname = "sddm";
  version = "unstable-2023-04-05";

  src = fetchFromGitHub {
    owner = "shawn8901";
    repo = "sddm";
    rev = "8a523530f5f39e8add22e38f7a7641e425fe47c3";
    sha256 = "sha256-fxA5Q7gcb1Al/M+XENR/VFo1RYp5TWvLe76shZcRK0w=";
  };

  patches = [
    ./sddm-ignore-config-mtime.patch
    ./sddm-default-session.patch
  ];

  postPatch =
    # Fix missing include for gettimeofday()
    ''
      sed -e '1i#include <sys/time.h>' -i src/helper/HelperApp.cpp
    '';

  nativeBuildInputs = [cmake extra-cmake-modules pkg-config qttools];

  buildInputs = [
    libxcb
    libpthreadstubs
    libXdmcp
    libXau
    pam
    qtbase
    qtdeclarative
    qtquickcontrols2
    systemd
  ];

  cmakeFlags = [
    "-DCONFIG_FILE=/etc/sddm.conf"
    # Set UID_MIN and UID_MAX so that the build script won't try
    # to read them from /etc/login.defs (fails in chroot).
    # The values come from NixOS; they may not be appropriate
    # for running SDDM outside NixOS, but that configuration is
    # not supported anyway.
    "-DUID_MIN=1000"
    "-DUID_MAX=29999"

    "-DQT_IMPORTS_DIR=${placeholder "out"}/${qtbase.qtQmlPrefix}"
    "-DCMAKE_INSTALL_SYSCONFDIR=${placeholder "out"}/etc"
    "-DSYSTEMD_SYSTEM_UNIT_DIR=${placeholder "out"}/lib/systemd/system"
    "-DDBUS_CONFIG_DIR=${placeholder "out"}/share/dbus-1/system.d"
    "-DSYSTEMD_SYSUSERS_DIR=${placeholder "out"}/lib/sysusers.d"
    "-DSYSTEMD_TMPFILES_DIR=${placeholder "out"}/lib/tmpfiles.d"
  ];

  postInstall = ''
    # remove empty scripts
    rm "$out/share/sddm/scripts/Xsetup" "$out/share/sddm/scripts/Xstop"
    for f in $out/share/sddm/themes/**/theme.conf ; do
      substituteInPlace $f \
        --replace 'background=' "background=$(dirname $f)/"
    done
  '';

  meta = with lib; {
    description = "QML based X11 display manager";
    homepage = "https://github.com/sddm/sddm";
    maintainers = with maintainers; [abbradar ttuegel];
    platforms = platforms.linux;
    license = licenses.gpl2Plus;
  };
}
