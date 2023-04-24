{
  lib,
  stdenv,
  fetchurl,
  makeDesktopItem,
  makeWrapper,
  icoutils,
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
  };
  version = "5.30.520";
  deezer-windows-app = fetchurl {
    url = "https://www.deezer.com/desktop/download/artifact/win32/x86/${version}";
    hash = "sha256-RfyshGi2togvdJjyJsEgXXlaYgX6CrlZF/XUzXDy+2c=";
  };
in
  stdenv.mkDerivation {
    pname = "deezer";
    inherit version;

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
      icoutils
    ];

    dontConfigure = true;

    unpackPhase = ''
      runHook preUnpack
      7z x -so ${deezer-windows-app} "\''$PLUGINSDIR/app-32.7z" > app-32.7z
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

      cd resources

      asar pack app app.asar
      cp app/build/main.js .

      cd ..
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/deezer" "$out/share/deezer/linux" "$out/share/icons/" "$out/share/applications" "$out/bin/"  $out/app

      icotool -x "resources/win/app.ico"
      for f in app_*.png; do
        res=$(basename "$f" ".png" | cut -d"_" -f3 | cut -d"x" -f1-2)
        mkdir -pv "$out/share/icons/hicolor/$res/apps"
        mv "$f" "$out/share/icons/hicolor/$res/apps/deezer.png"
      done;

      install -m644 resources/app.asar "$out/share/deezer/"
      install -m644 resources/win/systray.png "$out/share/deezer/linux/"

      makeWrapper ${electron_13}/bin/electron $out/bin/deezer \
        --add-flags $out/share/deezer/app.asar \
        --chdir $out/share/deezer

      ln -s ${desktop}/share/applications/* $out/share/applications

      runHook postInstall
    '';

    meta = with lib; {
      maintainers = with maintainers; [shawn8901];
      platforms = ["x86_64-linux"];
    };
  }
