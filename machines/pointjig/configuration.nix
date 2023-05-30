{
  config,
  inputs,
  pkgs,
  ...
}: let
  inherit (config.sops) secrets;
  inherit (inputs) mimir mimir-client stfc-bot;
in {
  sops.secrets = {
    sms-technical-passwd = {};
    sms-shawn-passwd = {};
    mimir-env = {
      owner = "mimir";
      group = "mimir";
    };
    stfc-env = {
      owner = "stfc-bot";
      group = "stfc-bot";
    };
    prometheus-web-config = {
      owner = "prometheus";
      group = "prometheus";
    };
  };

  networking .firewall = {
    allowedUDPPorts = [443];
    allowedTCPPorts = [80 443];
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "enp6s18";
          networkConfig.Address = ["134.255.226.114/28" "2a05:bec0:1:16::114/64"];
          networkConfig.DNS = "8.8.8.8";
          networkConfig.Gateway = "134.255.226.113";
          routes = [
            {
              routeConfig = {
                Gateway = "2a05:bec0:1:16::1";
                GatewayOnLink = "yes";
              };
            }
          ];
        };
      };
      wait-online.anyInterface = true;
    };
  };

  services = {
    fstrim.enable = true;
    postgresql.settings = {
      max_connections = 200;
      effective_cache_size = "256MB";
      shared_buffers = "256MB";
      work_mem = "16MB";
      track_activities = true;
      track_counts = true;
      track_io_timing = true;
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
        "status.${config.networking.hostName}.de" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;

          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.prometheus.port}";
          };
        };
      };
    };
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      retentionTime = "90d";
      globalConfig = {
        external_labels = {machine = "${config.networking.hostName}";};
      };
      webConfigFile = secrets.prometheus-web-config.path;
      webExternalUrl = "https://status.pointjig.de";
    };
    stne-mimir = {
      enable = true;
      domain = "mimir.pointjig.de";
      clientPackage = mimir-client.packages.x86_64-linux.default;
      package = mimir.packages.x86_64-linux.default;
      envFile = secrets.mimir-env.path;
      unixSocket = "/run/mimir-backend/mimir-backend.sock";
    };
    stfc-bot = {
      enable = true;
      package = stfc-bot.packages.x86_64-linux.default;
      envFile = secrets.stfc-env.path;
    };
  };

  mailserver = {
    enable = true;
    fqdn = "mail.pointjig.de";
    domains = ["pointjig.de"];
    certificateScheme = 3; # Upgrade to "acme-nginx";
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
          "wb@pointjig.de"
          "zsa@pointjig.de"
        ];
      };
      "dorman@pointjig.de" = {
        hashedPasswordFile = "${secrets.sms-shawn-passwd.path}";
        aliases = [
          "ninjatrader@pointjig.de"
        ];
      };
      "noreply@pointjig.de" = {
        hashedPasswordFile = "${secrets.sms-technical-passwd.path}";
      };
      "hydra@pointjig.de" = {
        hashedPasswordFile = "${secrets.sms-technical-passwd.path}";
      };
    };
  };

  security = {
    auditd.enable = false;
    audit.enable = false;
  };

  shawn8901 = {
    postgresql.enable = true;
  };
}
