{ config, pkgs, ... }:
let
  buildFirefoxXpiAddon = pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon;

in
{
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
  };

  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      forceWayland = true;
      extraPolicies = {
        ExtensionSettings = { };
      };
    };
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      ublock-origin
      umatrix
      keepassxc-browser
      (buildFirefoxXpiAddon {
        pname = "Tampermonkey";
        version = "4.13.6136";
        addonId = "firefox@tampermonkey.net";
        url = "https://addons.mozilla.org/firefox/downloads/file/3768983/tampermonkey-4.13.6136-an+fx.xpi";
        sha256 = "sha256-7ogucKRkqnIyJsmuc7WYwk5uENGCG1EmwH6FPOGmhWc=";
        meta = { };
      })
      (buildFirefoxXpiAddon {
        pname = "Video-DownloadHelper";
        version = "7.6.0";
        addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
        url = "https://addons.mozilla.org/firefox/downloads/file/3804074/video_downloadhelper-7.6.0-fx.xpi";
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
      };
    };
  };
}
