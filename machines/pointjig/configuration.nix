{
  config,
  inputs',
  pkgs,
  self',
  lib,
  ...
}:
let
  inherit (config.sops) secrets;
  fPkgs = self'.packages;
in
{
  sops.secrets = {
    sms-technical-passwd = { };
    sms-shawn-passwd = { };
    mimir-env = {
      owner = "mimir";
      group = "mimir";
    };
    stfc-env = {
      owner = "stfc-bot";
      group = "stfc-bot";
    };
    stalwart-fallback-admin = { };
  };

  networking.firewall = {
    allowedUDPPorts = [ 443 ];
    allowedTCPPorts = [
      80
      443
    ];
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "enp6s18";
          networkConfig = {
            Address = [
              "134.255.226.114/28"
              "2a05:bec0:1:16::114/64"
            ];
            DNS = "8.8.8.8";
            Gateway = "134.255.226.113";
          };
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
      shared_buffers = "1GB";
      effective_cache_size = "3GB";
      maintenance_work_mem = "256MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 4;
      effective_io_concurrency = 2;
      work_mem = "1310kB";
      huge_pages = "off";
      min_wal_size = "1GB";
      max_wal_size = "4GB";

      track_activities = true;
      track_counts = true;
      track_io_timing = true;
    };
    nginx = {
      package = pkgs.nginxQuic;
      virtualHosts."mail.pointjig.de" = {
        serverName = "mail.pointjig.de";
        forceSSL = true;
        enableACME = true;
        http3 = true;
        kTLS = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:8080";
            recommendedProxySettings = true;
          };
        };
      };
    };
    stne-mimir = {
      enable = true;
      domain = "mimir.pointjig.de";
      clientPackage = inputs'.mimir-client.packages.default;
      package = inputs'.mimir.packages.default;
      envFile = secrets.mimir-env.path;
      unixSocket = "/run/mimir-backend/mimir-backend.sock";
    };
    stfc-bot = {
      enable = true;
      package = inputs'.stfc-bot.packages.default;
      envFile = secrets.stfc-env.path;
    };
    stalwart-mail = {
      enable = true;
      package = fPkgs.stalwart-mail_0_7;
      http = {
        listenAddress = "127.0.0.1";
        port = 8080;
        openFirewall = false;
        tls = false;
      };
      environmentFile = secrets.stalwart-fallback-admin.path;
      hostname = "mail.pointjig.de";
      settings = {
        certificate.default = {
          private-key = "%{file:/var/lib/acme/mail.pointjig.de/key.pem}%";
          cert = "%{file:/var/lib/acme/mail.pointjig.de/cert.pem}%";
          default = true;
        };
        server.http.use-x-forwarded = true;
      };
    };
  };

  # So that we can read acme certificate from nginx
  users.users.stalwart-mail.extraGroups = [ "nginx" ];

  security = {
    auditd.enable = false;
    audit.enable = false;
  };

  shawn8901 = {
    postgresql.enable = true;
    server.enable = true;
    managed-user.enable = true;
  };
}
