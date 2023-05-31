{
  self,
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  hosts = self.nixosConfigurations;
  inherit (config.sops) secrets;
  inherit (pkgs.hostPlatform) system;
  inherit (inputs) attic;
in {
  sops.secrets = {
    root = {neededForUsers = true;};
    attic-env = {};
    prometheus-pve = {};
    grafana-env = {
      owner = "grafana";
      group = "grafana";
    };
    wireguard-priv-key = {};
    wireguard-preshared-key = {};
  };

  networking = {
    firewall = {
      allowedUDPPorts = [443 51820];
      allowedUDPPortRanges = [];
      allowedTCPPorts = [80 443];
      allowedTCPPortRanges = [];
    };
    nameservers = ["208.67.222.222" "208.67.220.220"];
    domain = "";
    useDHCP = true;
    wg-quick.interfaces = {
      wg0 = {
        listenPort = 51820;
        privateKeyFile = secrets.wireguard-priv-key.path;
        dns = ["192.168.11.1"] ++ config.networking.nameservers;
        address = [" 192.168.11.204/24"];
        peers = [
          {
            publicKey = "98gCbQmLB/W8Q1o1Zve/bSdZpAA1UuRvfjvXeVwEdQ4=";
            allowedIPs = ["192.168.11.0/24"];
            endpoint = "qy3w1d6525raac36.myfritz.net:54368";
            presharedKeyFile = secrets.wireguard-preshared-key.path;
            persistentKeepalive = 60;
          }
        ];
      };
    };
  };
  systemd = {
    services.grafana.serviceConfig.EnvironmentFile = [secrets.grafana-env.path];
    services.wg-quick-wg0.serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  services = {
    wireguard.reresolve-dns = {
      enable = true;
      package = self.packages.${system}.wg-reresolve-dns;
    };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "2G";
      virtualHosts = {
        "cache.pointjig.de" = {
          enableACME = true;
          forceSSL = true;
          http3 = false;
          http2 = false;
          kTLS = true;
          extraConfig = ''
            client_header_buffer_size 64k;
          '';
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080";
            recommendedProxySettings = true;
          };
        };
        "${config.services.grafana.settings.server.domain}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
      };
    };
    fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      bantime-increment.enable = true;
    };
    atticd = {
      enable = true;
      package = attic.packages.${system}.attic;
      credentialsFile = secrets.attic-env.path;
      settings = {
        allowed-hosts = ["cache.pointjig.de"];
        api-endpoint = "https://cache.pointjig.de/";
        database = {
          url = "postgresql:///attic?host=/run/postgresql";
          heartbeat = true;
        };
        chunking = {
          nar-size-threshold = 65536;
          min-size = 16384;
          avg-size = 65536;
          max-size = 262144;
        };
        compression = {type = "zstd";};
        garbage-collection.default-retention-period = "3 months";
      };
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      ensureDatabases = [
        "attic"
        "${config.services.grafana.settings.database.name}"
      ];
      ensureUsers = [
        {
          name = "atticd";
          ensurePermissions = {"DATABASE attic" = "ALL PRIVILEGES";};
        }
        {
          name = "${config.services.grafana.settings.database.user}";
          ensurePermissions = {"DATABASE ${config.services.grafana.settings.database.name}" = "ALL PRIVILEGES";};
        }
      ];
    };
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9001;
      retentionTime = "90d";
      globalConfig = {
        external_labels = {machine = "${config.networking.hostName}";};
      };
      scrapeConfigs = let
        nodePort = toString config.services.prometheus.exporters.node.port;
        postgresPort = toString config.services.prometheus.exporters.postgres.port;
        nextcloudPort = toString config.services.prometheus.exporters.nextcloud.port;
        pvePort = toString config.services.prometheus.exporters.pve.port;
        labels = {machine = "${config.networking.hostName}";};
      in [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["localhost:${nodePort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "postgres";
          static_configs = [
            {
              targets = ["localhost:${postgresPort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "proxmox";
          metrics_path = "/pve";
          params = {"target" = ["wi.clansap.org"];};
          static_configs = [{targets = ["localhost:${toString pvePort}"];}];
        }
      ];
      exporters = {
        node = {
          enable = true;
          listenAddress = "localhost";
          port = 9101;
          enabledCollectors = ["systemd"];
        };
        postgres = {
          enable = true;
          listenAddress = "localhost";
          port = 9187;
          runAsLocalSuperUser = true;
        };
        pve = {
          enable = true;
          listenAddress = "localhost";
          port = 9221;
          configFile = secrets.prometheus-pve.path;
        };
      };
    };
    grafana = {
      enable = true;
      settings = {
        server = rec {
          domain = "grafana.pointjig.de";
          http_addr = "127.0.0.1";
          http_port = 3001;
          root_url = "https://${domain}/";
          enable_gzip = true;
        };
        database = {
          type = "postgres";
          host = "/run/postgresql";
          user = "grafana";
          password = "$__env{DB_PASSWORD}";
        };
        security = {
          admin_password = "$__env{ADMIN_PASSWORD}";
          secret_key = "$__env{SECRET_KEY}";
          cookie_secure = true;
          content_security_policy = true;
        };
        smtp = {
          enabled = true;
          host = "pointjig.de:465";
          user = "noreply@pointjig.de";
          password = "$__env{SMTP_PASSWORD}";
          from_address = "noreply@pointjig.de";
        };
        analytics = {
          check_for_updates = false;
          reporting_enabled = false;
        };
        alerting.enabled = false;
        unified_alerting.enabled = true;
      };
      provision = {
        enable = true;
        datasources.settings.datasources = let
          pointalphaPrometheusPort = toString hosts.pointalpha.config.services.prometheus.port;
          tankPrometheusPort = toString hosts.tank.config.services.prometheus.port;
        in [
          {
            name = "localhost";
            type = "prometheus";
            url = "http://localhost:${toString config.services.prometheus.port}";
          }
          {
            name = "tank";
            type = "prometheus";
            url = "http://tank.fritz.box:${tankPrometheusPort}";
            basicAuth = true;
            withCredentials = true;
            basicAuthUser = "admin";
            secureJsonData.basicAuthPassword = "$__env{INTERNAL_PASSWORD}";
            jsonData.prometheusType = "Prometheus";
          }
          {
            name = "pointalpha";
            type = "prometheus";
            url = "http://pointalpha.fritz.box:${pointalphaPrometheusPort}";
            basicAuth = true;
            withCredentials = true;
            basicAuthUser = "admin";
            secureJsonData.basicAuthPassword = "$__env{INTERNAL_PASSWORD}";
            jsonData.prometheusType = "Prometheus";
          }
          {
            name = "pointjig";
            type = "prometheus";
            url = "https://status.pointjig.de";
            basicAuth = true;
            withCredentials = true;
            basicAuthUser = "admin";
            secureJsonData.basicAuthPassword = "$__env{PUBLIC_PASSWORD}";
            jsonData.prometheusType = "Prometheus";
          }
          {
            name = "shelter";
            type = "prometheus";
            url = "https://status.shelter.pointjig.de";
            basicAuth = true;
            withCredentials = true;
            basicAuthUser = "admin";
            secureJsonData.basicAuthPassword = "$__env{PUBLIC_PASSWORD}";
            jsonData.prometheusType = "Prometheus";
          }
          {
            name = "next";
            type = "prometheus";
            url = "https://status.next.clansap.org";
            basicAuth = true;
            withCredentials = true;
            basicAuthUser = "admin";
            secureJsonData.basicAuthPassword = "$__env{PUBLIC_PASSWORD}";
            jsonData.prometheusType = "Prometheus";
          }
        ];
      };
    };
  };

  users.mutableUsers = false;
  users.users.root = {
    passwordFile = secrets.root.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N"
    ];
  };

  shawn8901.auto-upgrade.enable = true;
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  security = {
    auditd.enable = false;
    audit.enable = false;
    acme = {
      acceptTerms = true;
      defaults.email = "shawn@pointjig.de";
    };
  };
  environment.noXlibs = true;
}
