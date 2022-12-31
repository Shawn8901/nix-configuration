{ lib, stdenv, fetchurl, ... } @args:
let
  buildFirefoxXpiAddon = lib.makeOverridable ({ stdenv ? args.stdenv
                                              , fetchurl ? args.fetchurl
                                              , pname
                                              , version
                                              , addonId
                                              , url
                                              , sha256
                                              , meta
                                              , ...
                                              }:
    stdenv.mkDerivation {
      name = "${pname}-${version}";

      inherit meta;

      src = fetchurl { inherit url sha256; };

      preferLocalBuild = true;
      allowSubstitutes = true;

      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    });

  vdh = buildFirefoxXpiAddon {
    pname = "Video-DownloadHelper";
    version = "7.6.0";
    addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3804074/video_downloadhelper-7.6.0-fx.xpi";
    sha256 = "sha256-vVHZwQZOhpogQDAS4BAxm0bvCrcrsz8ioxDdOqsnelM=";
    meta = { };
  };
  ublock-origin = buildFirefoxXpiAddon {
    pname = "ublock-origin";
    version = "1.46.0";
    addonId = "uBlock0@raymondhill.net";
    url = "https://addons.mozilla.org/firefox/downloads/file/4047353/ublock_origin-1.46.0.xpi";
    sha256 = "6bf8af5266353fab5eabdc7476de026e01edfb7901b0430c5e539f6791f1edc8";
    meta = with lib;
      {
        homepage = "https://github.com/gorhill/uBlock#ublock-origin";
        description = "Finally, an efficient wide-spectrum content blocker. Easy on CPU and memory.";
        license = licenses.gpl3;
        platforms = platforms.all;
      };
  };

  umatrix = buildFirefoxXpiAddon {
    pname = "umatrix";
    version = "1.4.4";
    addonId = "uMatrix@raymondhill.net";
    url = "https://addons.mozilla.org/firefox/downloads/file/3812704/umatrix-1.4.4.xpi";
    sha256 = "1de172b1d82de28c334834f7b0eaece0b503f59e62cfc0ccf23222b8f2cb88e5";
    meta = with lib;
      {
        homepage = "https://github.com/gorhill/uMatrix";
        description = "Point &amp; click to forbid/allow any class of requests made by your browser. Use it to block scripts, iframes, ads, facebook, etc.";
        license = licenses.gpl3;
        platforms = platforms.all;
      };
  };
  keepassxc-browser = buildFirefoxXpiAddon {
    pname = "keepassxc-browser";
    version = "1.8.4";
    addonId = "keepassxc-browser@keepassxc.org";
    url = "https://addons.mozilla.org/firefox/downloads/file/4045866/keepassxc_browser-1.8.4.xpi";
    sha256 = "cc39aa058cb8915cfc88424e2e1cebe3ccfc3f95d7bddb2abd0c4905d2b17719";
    meta = with lib;
      {
        homepage = "https://keepassxc.org/";
        description = "Official browser plugin for the KeePassXC password manager (<a rel=\"nofollow\" href=\"https://prod.outgoing.prod.webservices.mozgcp.net/v1/aebde84f385b73661158862b419dd43b46ac4c22bea71d8f812030e93d0e52d5/https%3A//keepassxc.org\">https://keepassxc.org</a>).";
        license = licenses.gpl3;
        platforms = platforms.all;
      };
  };

  plasma-integration = buildFirefoxXpiAddon {
    pname = "plasma-integration";
    version = "1.8.1";
    addonId = "plasma-browser-integration@kde.org";
    url = "https://addons.mozilla.org/firefox/downloads/file/3859385/plasma_integration-1.8.1.xpi";
    sha256 = "e156e82091bbff44cb9d852e16aedacdcc0819c5a3b8cb34cedd77acf566c5c4";
    meta = with lib;
      {
        homepage = "http://kde.org";
        description = "Multitask efficiently by controlling browser functions from the Plasma desktop.";
        license = licenses.gpl3;
        platforms = platforms.all;
      };
  };

  tampermonkey = buildFirefoxXpiAddon {
    pname = "tampermonkey";
    version = "4.18.1";
    addonId = "firefox@tampermonkey.net";
    url = "https://addons.mozilla.org/firefox/downloads/file/4030629/tampermonkey-4.18.1.xpi";
    sha256 = "edb43812730e5b8d866589de7ab8d80e7932cab49a2fa10d2bc2b8be374ebcde";
    meta = with lib;
      {
        homepage = "https://tampermonkey.net";
        description = "Tampermonkey is the world's most popular userscript manager.";
        license = {
          shortName = "tampermonkey";
          fullName = "End-User License Agreement for Tampermonkey";
          url = "https://addons.mozilla.org/en-US/firefox/addon/tampermonkey/eula/";
          free = false;
        };
        platforms = platforms.all;
      };
  };

  betterttv = buildFirefoxXpiAddon {
    pname = "betterttv";
    version = "7.4.40";
    addonId = "firefox@betterttv.net";
    url = "https://addons.mozilla.org/firefox/downloads/file/4009945/betterttv-7.4.40.xpi";
    sha256 = "1353faa304cd7e6bf0039d9897afbf8014e1ff0ef5646db3207405e2a00684dd";
    meta = with lib;
      {
        homepage = "https://betterttv.com";
        description = "Enhances Twitch with new features, emotes, and more.";
        license = {
          shortName = "betterttv";
          fullName = "BetterTTV Terms of Service";
          url = "https://betterttv.com/terms";
          free = false;
        };
        platforms = platforms.all;
      };
  };

  h264ify = buildFirefoxXpiAddon {
    pname = "h264ify";
    version = "1.1.0";
    addonId = "jid1-TSgSxBhncsPBWQ@jetpack";
    url = "https://addons.mozilla.org/firefox/downloads/file/3398929/h264ify-1.1.0.xpi";
    sha256 = "87bd3c4ab1a2359c01a1d854d7db8428b44316fef5b2ac09e228c5318c57a515";
    meta = with lib;
      {
        description = "Makes YouTube stream H.264 videos instead of VP8/VP9 videos";
        license = licenses.mit;
        platforms = platforms.all;
      };
  };
in
{
  inherit
    buildFirefoxXpiAddon
    vdh
    ublock-origin
    umatrix
    keepassxc-browser
    plasma-integration
    tampermonkey
    betterttv
    h264ify;
}
