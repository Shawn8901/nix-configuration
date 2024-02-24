{ lib
, stdenv
, fetchurl
, fetchzip
, makeDesktopItem
, copyDesktopItems
, makeWrapper
, writeScript
, imagemagick
, p7zip
, nodePackages
, electron_13
,
}:
let
  desktopItem = makeDesktopItem {
    name = "deezer";
    desktopName = "Deezer";
    comment = "Deezer audio streaming service";
    icon = "deezer";
    categories = [ "Audio" "Music" "Player" "AudioVideo" ];
    type = "Application";
    mimeTypes = [ "x-scheme-handler/deezer" ];
    startupWMClass = "deezer";
    exec = "deezer %u";
    startupNotify = true;
  };
  shortenVersion = v:
    lib.concatStringsSep "." (lib.sublist 0 3 (lib.splitVersion v));

in
stdenv.mkDerivation (finalAttrs: {

  version = "6.0.70";
  pname = "deezer";

  src = fetchzip {
    url =
      "https://github.com/SibrenVasse/${finalAttrs.pname}/archive/refs/tags/v${finalAttrs.version}.tar.gz";
    hash = "sha256-A3ibtwJczq8fZxj9PvqYWI3+TQN/XsfvXoZst3oTdnM=";
  };

  # this is a nasty workaround to trick nix-update to update your hash, whilst having src on the github repo
  # that is providing patches, whilst also updating a second hash
  go-modules = fetchurl {
    url = "https://www.deezer.com/desktop/download/artifact/win32/x86/${
        shortenVersion finalAttrs.version
      }";
    hash = "sha256-kOE/3Nh3bpRj/Po9q35YAcPuHYBa5pQv9+MqKGgAscM=";
  };

  patches = [
    "${finalAttrs.src}/remove-kernel-version-from-user-agent.patch"
    "${finalAttrs.src}/avoid-change-default-texthtml-mime-type.patch"
    "${finalAttrs.src}/start-hidden-in-tray.patch"
    "${finalAttrs.src}/quit.patch"
  ];

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
    p7zip
    nodePackages.asar
    nodePackages.prettier
    imagemagick
  ];

  dontConfigure = true;

  prePatch = ''
    7z x -so ${finalAttrs.go-modules} "\$PLUGINSDIR/app-32.7z" > app-32.7z
    7z x -y -bsp0 -bso0 app-32.7z

    cd resources
    asar extract app.asar app
    prettier --write "app/build/*.js"

    substituteInPlace app/build/main.js \
      --replace "return external_path_default().join(process.resourcesPath, appIcon);" \
      "return external_path_default().join('$out', 'share/deezer/', appIcon);"

    cd ..

    cd resources/app
  '';

  postPatch = ''
    cd ../..
  '';

  buildPhase = ''
    runHook preBuild

    cd resources

    asar pack app app.asar
    cp app/build/main.js .

    cd ..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/deezer" "$out/share/deezer/linux" "$out/share/applications" "$out/bin/"  $out/app

    for size in 16 32 48 64 128 256; do
      mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps/"
    done

    convert resources/win/app.ico resources/win/deezer.png
    install -Dm644 resources/win/deezer-0.png "$out/share/icons/hicolor/16x16/apps/deezer.png"
    install -Dm644 resources/win/deezer-1.png "$out/share/icons/hicolor/32x32/apps/deezer.png"
    install -Dm644 resources/win/deezer-2.png "$out/share/icons/hicolor/48x48/apps/deezer.png"
    install -Dm644 resources/win/deezer-3.png "$out/share/icons/hicolor/64x64/apps/deezer.png"
    install -Dm644 resources/win/deezer-4.png "$out/share/icons/hicolor/128x128/apps/deezer.png"
    install -Dm644 resources/win/deezer-5.png "$out/share/icons/hicolor/256x256/apps/deezer.png"

    install -m644 resources/app.asar "$out/share/deezer/"
    install -m644 resources/win/systray.png "$out/share/deezer/linux/"

    makeWrapper ${electron_13}/bin/electron $out/bin/deezer \
      --add-flags $out/share/deezer/app.asar \
      --chdir $out/share/deezer

    runHook postInstall
  '';

  desktopItems = [ desktopItem ];

  passthru.runUpdate = true;

  meta = with lib; {
    maintainers = with maintainers; [ shawn8901 ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
})
