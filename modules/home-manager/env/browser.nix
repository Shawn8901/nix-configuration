{
  self,
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (inputs) firefox-addons;
  inherit (firefox-addons.lib.${system}) buildFirefoxXpiAddon;
  inherit (pkgs.hostPlatform) system;

  fPkgs = self.packages.${system};
  cfg = config.shawn8901.browser;
  firefox-addon-packages = firefox-addons.packages.${system};
in {
  options = {
    shawn8901.browser = {
      enable = mkEnableOption "Enable browser on the environment";
    };
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        extraNativeMessagingHosts = [fPkgs.vdhcoapp];
      };
      profiles."shawn" = {
        extensions = with firefox-addon-packages; [
          ublock-origin
          umatrix
          keepassxc-browser
          plasma-integration
          h264ify

          # Tampermonkey has an unfree lisence and some can not pass a
          # nixpkgs.config.allowUnfreePredicate to a flake input.
          # So overriding the stdenv is the only solution here to use the hosts
          # nixpkgs.config.allowUnfreePredicate.
          (tampermonkey.override {inherit (pkgs) stdenv fetchurl;})
          (betterttv.override {inherit (pkgs) stdenv fetchurl;})

          # Download all plugins which are not in the repo manually
          (buildFirefoxXpiAddon {
            pname = "Video-DownloadHelper";
            version = "7.6.0";
            addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
            url = "https://addons.mozilla.org/firefox/downloads/file/3804074/video_downloadhelper-7.6.0-fx.xpi";
            sha256 = "sha256-vVHZwQZOhpogQDAS4BAxm0bvCrcrsz8ioxDdOqsnelM=";
            meta = {};
          })
        ];
        settings = {
          "app.update.auto" = false;
          "browser.crashReports.unsubmittedCheck.enabled" = false;
          "browser.newtab.preload" = false;
          "browser.newtabpage.activity-stream.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.ping-centre.telemetry" = false;
          "browser.safebrowsing.malware.enabled" = true;
          "browser.safebrowsing.phishing.enabled" = true;
          "browser.send_pings" = false;
          "device.sensors.enabled" = false;
          "dom.battery.enabled" = false;
          "dom.webaudio.enabled" = false;
          "experiments.enabled" = false;
          "experiments.supported" = false;
          "privacy.donottrackheader.enabled" = true;
          "privacy.firstparty.isolate" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          "privacy.trackingprotection.pbmode.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "security.ssl.errorReporting.automatic" = false;
          "services.sync.engine.addons" = false;
          "services.sync.addons.ignoreUserEnabledChanges" = true;
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.hybridContent.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.reportingpolicy.firstRun" = false;
          "toolkit.telemetry.server" = "";
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "gfx.webrender.compositor.force-enabled" = true;
          "browser.cache.disk.enable" = false;
          "browser.cache.memory.enable" = true;
          "extensions.pocket.enabled" = false;

          "media.ffmpeg.vaapi.enabled" = true;
          "media.ffvpx.enabled" = false;
          "media.navigator.mediadatadecoder_vpx_enabled" = true;
          "media.rdd-vpx.enabled" = false;
        };
      };
    };
  };
}
