{ prev
, lib, stdenv, fetchurl, makeWrapper, makeDesktopItem, zlib, glib, libpng, freetype, openssl
, xorg, fontconfig, qtbase, qtwebengine, qtwebchannel, qtsvg, qtwebsockets, xkeyboard_config
, alsa-lib, libpulseaudio ? null, libredirect, quazip, which, unzip, llvmPackages_10, writeShellScriptBin
 }:
let
  arch = if stdenv.is64bit then "amd64" else "x86";
  libDir = if stdenv.is64bit then "lib64" else "lib";
  deps =
    [ zlib glib libpng freetype xorg.libSM xorg.libICE xorg.libXrender openssl
      xorg.libXrandr xorg.libXfixes xorg.libXcursor xorg.libXinerama
      xorg.libxcb fontconfig xorg.libXext xorg.libX11 alsa-lib qtbase qtwebengine qtwebchannel qtsvg
      qtwebsockets libpulseaudio quazip llvmPackages_10.libcxx llvmPackages_10.libcxxabi # llvmPackages_11 and higher crash https://github.com/NixOS/nixpkgs/issues/161395
    ];
in

prev.teamspeak_client.overrideAttrs (oldAttrs: rec {
    buildPhase =
    ''
      mv ts3client_linux_${arch} ts3client
      echo "patching ts3client..."
      patchelf --replace-needed libquazip.so ${quazip}/lib/libquazip1-qt5.so ts3client
      patchelf \
        --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath ${lib.makeLibraryPath deps}:$(cat $NIX_CC/nix-support/orig-cc)/${libDir} \
        --force-rpath \
        ts3client
    '';
})
