{ config, inputs, pkgs, ... }:
let
  secrets = config.age.secrets;
  inherit (inputs) stfc-bot mimir;
in
{
  imports = [ stfc-bot.nixosModule mimir.nixosModule ];

  age.secrets = {
    sms-shawn-passwd = {
      file = ../../secrets/sms-shawn-passwd.age;
      owner = "stfc-bot";
      group = "stfc-bot";
    };
    stfc-env = {
      file = ../../secrets/stfc-env.age;
      owner = "stfc-bot";
      group = "stfc-bot";
    };
    mimir-env = {
      file = ../../secrets/mimir-env.age;
      owner = "mimir";
      group = "mimir";
    };
  };

  networking = {
    firewall = {
      allowedUDPPorts = [ 443 ];
      allowedUDPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 ];
      allowedTCPPortRanges = [ ];
    };
    networkmanager.enable = false;
    dhcpcd.enable = false;
    useNetworkd = true;
    useDHCP = false;
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "enp6s18";
          networkConfig.Address =
            [ "134.255.226.114/28" "2a05:bec0:1:16::114/64" ];
          networkConfig.DNS = "8.8.8.8";
          networkConfig.Gateway = "134.255.226.113";
          routes = [{
            routeConfig = {
              Gateway = "2a05:bec0:1:16::1";
              GatewayOnLink = "yes";
            };
          }];
        };
      };
      wait-online.anyInterface = true;
    };
  };

  services = {
    xserver.enable = false;
    qemuGuest.enable = true;
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };
    resolved.enable = true;
    zfs = {
      autoScrub.enable = true;
      autoScrub.pools = [ "zbackup" ];
    };
    fail2ban = {
      enable = true;
      maxretry = 5;
    };
    vnstat.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=100M
    '';
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${config.services.stne-mimir.domain}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
        };
      };
    };
    stfc-bot = {
      enable = true;
      package = inputs.stfc-bot.packages.x86_64-linux.default;
      envFile = config.age.secrets.stfc-env.path;
    };
    stne-mimir = {
      enable = true;
      domain = "mimir.pointjig.de";
      clientPackage = inputs.mimir-client.packages.x86_64-linux.default;
      package = inputs.mimir.packages.x86_64-linux.default;
      envFile = config.age.secrets.mimir-env.path;
      unixSocket = "/run/mimir-backend/mimir-backend.sock";
    };
  };

  mailserver = {
    enable = true;
    fqdn = "mail.pointjig.de";
    domains = [ "pointjig.de" ];
    certificateScheme = 3;
    loginAccounts = {
      "shawn@pointjig.de" = {
        hashedPasswordFile = "${secrets.sms-shawn-passwd.path}";
        aliases = [
          "aktienfinder@pointjig.de"
          "alphavps@pointjig.de"
          "caseking@pointjig.de"
          "check24@pointjig.de"
          "codeberg@pointjig.de"
          "dropbox@pointjig.de"
          "epic@pointjig.de"
          "estateguru@pointjig.de"
          "flexispot@pointjig.de"
          "fritz@pointjig.de"
          "geizhals@pointjig.de"
          "git@pointjig.de"
          "megaprimus@pointjig.de"
          "mindfactory@pointjig.de"
          "ninjatrader@pointjig.de"
          "parqet@pointjig.de"
          "planetside@pointjig.de"
          "smite@pointjig.de"
          "spocks@pointjig.de"
          "spotify@pointjig.de"
          "steam@pointjig.de"
          "stfc@pointjig.de"
          "stne@pointjig.de"
          "sto@pointjig.de"
          "supremegamers@pointjig.de"
          "unity@pointjig.de"
          "zsa@pointjig.de"
        ];
      };
      "dorman@pointjig.de" = {
        hashedPasswordFile = "${secrets.sms-shawn-passwd.path}";
        aliases = [
          "ninjatrader@pointjig.de"
        ];
      };
    };
  };

  security.auditd.enable = false;
  security.audit.enable = false;
  security.acme = {
    acceptTerms = true;
    defaults.email = "shawn@pointjig.de";
  };
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  sound.enable = false;
  env.auto-upgrade.enable = true;
}
