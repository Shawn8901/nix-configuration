{ lib
, stdenv
, fetchurl
, makeDesktopItem
, makeWrapper
, p7zip
, nodePackages
, imagemagick
, electron_13
}:

let
  desktop = makeDesktopItem {
    name = "deezer";
    desktopName = "Deezer";
    comment = "Deezer audio streaming service";
    icon = "deezer";
    categories = [ "Audio" "Music" "Player" "AudioVideo" ];
    type = "Application";
    mimeTypes = [ "x-scheme-handler/deezer" ];
    startupWMClass = "deezer";
    exec = "deezer %u";
  };
in
stdenv.mkDerivation
  (finalAttrs: {

    pname = "deezer";

    version = "5.30.500";

    src = fetchurl {
      url = "https://www.deezer.com/desktop/download/artifact/win32/x86/${finalAttrs.version}";
      sha256 = "sha256-9kaRkRBjbrwXlKAHPv6AeVoRuGRJHh0sYEeBABb/fX0=";
    };

    patches = [
      ./avoid-change-default-texthtml-mime-type.patch
      ./fix-isDev-usage.patch
      ./remove-kernel-version-from-user-agent.patch
      ./start-hidden-in-tray.patch
      ./quit.patch
    ];

    nativeBuildInputs = [
      makeWrapper
      p7zip
      nodePackages.asar
      nodePackages.prettier
      imagemagick
    ];

    dontConfigure = true;

    unpackPhase = ''
      runHook preUnpack
      7z x -so ${finalAttrs.src} "\''$PLUGINSDIR/app-32.7z" > app-32.7z
      7z x -y -bsp0 -bso0 app-32.7z

      asar extract resources/app.asar resources/app

      prettier --write "resources/app/build/*.js"

       substituteInPlace resources/app/build/main.js \
         --replace "return external_path_default().join(process.resourcesPath, appIcon);" \
         "return external_path_default().join('$out', 'share/deezer/', appIcon);"

      runHook postUnpack
    '';


    prePatch = ''
      cd resources/app
    '';

    postPatch = ''
      cd ../..
    '';

    buildPhase = ''
      runHook preBuild

      mkdir resources/linux
      install -Dm644 "resources/win/systray.png" resources/linux/

      convert resources/win/app.ico resources/linux/deezer.png

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

      install -Dm644 resources/app.asar "$out/share/deezer/"
      install -Dm644 resources/win/systray.png "$out/share/deezer/linux/"

      mkdir $out/js
      install -Dm644 resources/main.js "$out/js"



      makeWrapper ${electron_13}/bin/electron $out/bin/deezer \
        --add-flags $out/share/deezer/app.asar \
        --chdir $out/share/deezer

      ln -s ${desktop}/share/applications/* $out/share/applications

      runHook postInstall
    '';


    meta = with lib; {
      maintainers = with maintainers; [ shawn8901 ];
      platforms = [ "x86_64-linux" ];
    };
  })
