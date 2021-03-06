{ nPkgs, ... }@inputs:
{ config, lib, pkgs, ... }:
with lib;
let
  inherit (nPkgs) nur;
  inherit (nur.repos.rycee.firefox-addons) buildFirefoxXpiAddon;
  cfg = config.env.browser;
in
{
  options = {
    env.browser = {
      enable = mkEnableOption "Enable browser on the environment";
      wayland = mkOption {
        type = types.bool;
        default = true;
        description = "Set true it wayland is used.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      MOZ_DISABLE_RDD_SANDBOX = 1;
    };

    programs.firefox = {
      enable = true;
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        forceWayland = true;
        extraNativeMessagingHosts = with nur.repos.wolfangaukang; [ vdhcoapp ];
      };
      extensions = with nur.repos.rycee.firefox-addons; [
        ublock-origin
        umatrix
        keepassxc-browser
        plasma-integration
        tampermonkey
        betterttv
        h264ify
        (buildFirefoxXpiAddon {
          pname = "Video-DownloadHelper";
          version = "7.6.0";
          addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
          url =
            "https://addons.mozilla.org/firefox/downloads/file/3804074/video_downloadhelper-7.6.0-fx.xpi";
          sha256 = "sha256-vVHZwQZOhpogQDAS4BAxm0bvCrcrsz8ioxDdOqsnelM=";
          meta = { };
        })
      ];
      profiles."shawn" = {
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
