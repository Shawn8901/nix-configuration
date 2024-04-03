{
  lib,
  pkgs,
  fetchFromGitHub,
  buildNpmPackage,
  toml2json,
  nodejs,
  ffmpeg,
  filepicker,
  substituteAll,
  makeWrapper,
}:
let
  appName = "vdhcoapp";

  generateManifest =
    {
      allowedSet ? { },
    }:
    pkgs.writeText "${appName}.json" (
      builtins.toJSON (
        lib.recursiveUpdate {
          name = appName;
          description = "Video DownloadHelper companion app";
          path = "DIR/${appName}";
          type = "stdio";
        } allowedSet
      )
    );

  firefoxManifest = generateManifest {
    allowedSet = {
      allowed_extensions = [
        "weh-native-test@downloadhelper.net"
        "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}"
      ];
    };
  };
  chromeManifest = generateManifest {
    allowedSet = {
      allowed_origins = [ "chrome-extension://lmjnegcaeklhafolokijcfjliaokphfk/" ];
    };
  };
in
# This is an adaptation with buildNpmPackage based on https://github.com/milahu/nur-packages/commit/3022ffb3619182ffcd579194e1202e3978e4d55b
buildNpmPackage rec {
  pname = "vdhcoapp";
  version = "2.0.19";

  src = fetchFromGitHub {
    owner = "aclap-dev";
    repo = "vdhcoapp";
    rev = "v${version}";
    hash = "sha256-8xeZvqpRq71aShVogiwlVD3gQoPGseNOmz5E3KbsZxU=";
  };

  sourceRoot = "${src.name}/app";
  npmDepsHash = "sha256-E032U2XZdyTER6ROkBosOTn7bweDXHl8voC3BQEz8Wg=";
  dontNpmBuild = true;

  nativeBuildInputs = [
    toml2json
    makeWrapper
  ];

  patches = [
    (substituteAll {
      src = ./code.patch;
      inherit ffmpeg;
      filepicker = lib.getExe filepicker;
    })
  ];

  postPatch = ''
    # Cannot use patch, setting placeholder here
    substituteInPlace src/native-autoinstall.js \
      --replace process.execPath "\"${placeholder "out"}/bin/vdhcoapp\""
  '';

  preBuild = ''
    toml2json --pretty ../config.toml > src/config.json
  '';

  installPhase = ''
    mkdir -p $out/opt/vdhcoapp

    cp -r . "$out/opt/vdhcoapp"

    makeWrapper ${nodejs}/bin/node $out/bin/vdhcoapp \
      --add-flags $out/opt/vdhcoapp/src/main.js

    installManifest() {
      install -d $2
      cp $1 $2/${appName}.json
      substituteInPlace $2/${appName}.json --replace DIR $out/bin
    }
    installManifest ${chromeManifest}  $out/etc/opt/chrome/native-messaging-hosts
    installManifest ${chromeManifest}  $out/etc/chromium/native-messaging-hosts
    installManifest ${firefoxManifest} $out/lib/mozilla/native-messaging-hosts
  '';

  meta = with lib; {
    description = "Companion application for the Video DownloadHelper browser add-on";
    homepage = "https://www.downloadhelper.net/";
    license = licenses.gpl2;
    maintainers = with maintainers; [ wolfangaukang ];
    mainProgram = "vdhcoapp";
  };
}
