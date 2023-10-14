{
  lib,
  stdenv,
  fetchurl,
  makeDesktopItem,
  makeWrapper,
  imagemagick,
  p7zip,
  nodePackages,
  electron_13,
  fetchFromGitHub,
}: let
  desktop = makeDesktopItem {
    name = "deezer";
    desktopName = "Deezer";
    comment = "Deezer audio streaming service";
    icon = "deezer";
    categories = ["Audio" "Music" "Player" "AudioVideo"];
    type = "Application";
    mimeTypes = ["x-scheme-handler/deezer"];
    startupWMClass = "deezer";
    exec = "deezer %u";
    startupNotify = true;
  };
  version = "5.30.670";
  deezer-windows-app = fetchurl {
    url = "https://www.deezer.com/desktop/download/artifact/win32/x86/${version}";
    hash = "sha256-llSG2w1y0lYy8ipwPjMH7lbno42Xrl6wGwtQPqo6tao=";
  };
in
  stdenv.mkDerivation {
    pname = "deezer";
    inherit version;

    patches = [
      ./remove-kernel-version-from-user-agent.patch
      ./avoid-change-default-texthtml-mime-type.patch
      ./fix-isDev-usage.patch
      ./start-hidden-in-tray.patch
      ./quit.patch
      ./systray-buttons-fix.patch
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
      7z x -so ${deezer-windows-app} "\''$PLUGINSDIR/app-32.7z" > app-32.7z
      7z x -y -bsp0 -bso0 app-32.7z

      cd resources
      asar extract app.asar app

      prettier --write "app/build/*.js"

      substituteInPlace app/build/main.js \
        --replace "return external_path_default().join(process.resourcesPath, appIcon);" \
        "return external_path_default().join('$out', 'share/deezer/', appIcon);"

      cd ..

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

      ln -s ${desktop}/share/applications/* $out/share/applications/deezer.desktop

      runHook postInstall
    '';

    meta = with lib; {
      maintainers = with maintainers; [shawn8901];
      platforms = ["x86_64-linux"];
    };
  }
