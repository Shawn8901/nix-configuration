{ lib
, buildFHSUserEnvBubblewrap
, jameica
, jre
, stdenv
, cairo
, fontconfig
, freetype
, gdk-pixbuf
, glib
, glibc
, gtk2
, libX11
, nspr
, nss
, pango
, libxcb
, libXi
, libXrender
, libXext
, dbus
, alsa-lib
, libXScrnSaver
, libXcursor
, libXtst
, libxshmfence
, libGLU
, libGL
, at-spi2-core
, libgcrypt
, cups
, libdrm
, wayland
, mesa
, libxkbcommon
, libXdamage
, libXcomposite
, libXfixes
, libXrandr
, libva
, expat
, udev
, killall
, webkitgtk
, extraPkgs ? pkgs: [ ]
, extraLibraries ? pkgs: [ ]
}:

let
  fhsEnv = buildFHSUserEnvBubblewrap {
    name = "jameica";
    runScript = "jameica";
    targetPkgs = pkgs: [
      jre
      jameica
      stdenv.cc.cc.lib
      cairo
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk2
      libX11
      nspr
      nss
      pango
      libXrender
      libxcb
      libXext
      libXi
      dbus

      alsa-lib
      libXScrnSaver
      libXcursor
      libXtst
      libxshmfence
      libGLU
      libGL
      at-spi2-core
      libgcrypt
      cups
      libdrm
      wayland
      mesa.drivers
      libxkbcommon
      libXdamage
      libXcomposite
      libXrandr
      libXfixes
      expat
      libva
      udev

      webkitgtk

      killall
    ] ++ extraPkgs pkgs;

    inherit (jameica) meta;
  };
in
fhsEnv
