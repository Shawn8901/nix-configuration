{
  lib,
  stdenv,
  fetchurl,
  makeDesktopItem,
  makeWrapper,
  p7zip,
  nodePackages,
  imagemagick,
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
in
  stdenv.mkDerivation
  (finalAttrs: {
    pname = "deezer";
    version = "5.30.510";

    deezer-windows-app = fetchurl {
      url = "https://www.deezer.com/desktop/download/artifact/win32/x86/${finalAttrs.version}";
      hash = "sha256-P/7F4Q+VfDn1B/69dZWWMYj0ri98db525BmcDoRkG44=";
    };

    linux_patch_upstream = fetchFromGitHub {
      owner = "aunetx";
      repo = "deezer-linux";
      rev = "d4fd8cd41d4c58ef5144f3d7cec79c2679e7dc2b";
      hash = "sha256-8LiBjn0j863Nlaau+/UvZGJc0CtneWPiY1eiC9be5gw=";
    };

    patches = [
      "${finalAttrs.linux_patch_upstream}/patches/avoid-change-default-texthtml-mime-type.patch"
      "${finalAttrs.linux_patch_upstream}/patches/fix-isDev-usage.patch"
      "${finalAttrs.linux_patch_upstream}/patches/remove-kernel-version-from-user-agent.patch"
      "${finalAttrs.linux_patch_upstream}/patches/start-hidden-in-tray.patch"
      "${finalAttrs.linux_patch_upstream}/patches/quit.patch"
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
      7z x -so ${finalAttrs.deezer-windows-app} "\''$PLUGINSDIR/app-32.7z" > app-32.7z
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

      mkdir -p "$out/share/deezer" "$out/share/deezer/linux" "$out/share/applications" "$out/bin/"  $out/app

      install -m644 resources/app.asar "$out/share/deezer/"
      ln -sf ${finalAttrs.linux_patch_upstream}/extra/linux/systray.png "$out/share/deezer/linux/"

      for size in 16 32 48 64 128 256; do
          mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps/"
          ln -sf ${finalAttrs.linux_patch_upstream}/icons/''${size}x''${size}.png "$out/share/icons/hicolor/''${size}x''${size}/apps/deezer.png"
      done

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
  })
