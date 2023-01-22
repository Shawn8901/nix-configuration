{ self, config, pkgs, lib, inputs, ... }:
let
  hosts = self.nixosConfigurations;
  secrets = config.age.secrets;
  system = pkgs.hostPlatform.system;
  inherit (inputs) attic;
in
{

  imports = [ attic.nixosModules.atticd ];

  age.secrets = {
    root_password_file = { file = ../../secrets/root_password.age; };
    attic_env = { file = ../../secrets/attic_env.age; };
    pve_prometheus = {
      file = ../../secrets/pve_prometheus.age;
    };
    grafana_env_file = {
      file = ../../secrets/grafana_env_file.age;
      owner = "grafana";
      group = "grafana";
    };
    cache-wg-priv-key = {
      file = ../../secrets/cache-wg-priv-key.age;
    };
    cache-wg-preshared-key = {
      file = ../../secrets/cache-wg-preshared-key.age;
    };
  };

  networking = {
    firewall = {
      allowedUDPPorts = [ 443 51820 ];
      allowedUDPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 ];
      allowedTCPPortRanges = [ ];
    };
    domain = "";
    useDHCP = true;
    wg-quick.interfaces = {
      wg0 = {
        listenPort = 51820;
        privateKeyFile = secrets.cache-wg-priv-key.path;
        dns = [ "192.168.11.1" ];
        address = [ " 192.168.11.204/24" ];
        peers = [
          {
            publicKey = "98gCbQmLB/W8Q1o1Zve/bSdZpAA1UuRvfjvXeVwEdQ4=";
            allowedIPs = [ "192.168.11.0/24" ];
            endpoint = "qy3w1d6525raac36.myfritz.net:54368";
            presharedKeyFile = secrets.cache-wg-preshared-key.path;
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
  systemd = {
    services.grafana.serviceConfig.EnvironmentFile = [
      secrets.grafana_env_file.path
    ];
  };
  services = {
    resolved.enable = true;
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
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
    atticd = {
      enable = true;
      package = attic.packages.${system}.attic-nixpkgs;
      credentialsFile = secrets.attic_env.path;
      settings = {
        allowed-hosts = [ "cache.pointjig.de" ];
        api-endpoint = "https://cache.pointjig.de/";
        database.url = "postgresql:///attic?host=/run/postgresql";
        chunking = { nar-size-threshold = 65536; min-size = 16384; avg-size = 65536; max-size = 262144; };
        compression = { type = "zstd"; };
      };
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      ensureDatabases = [
        "attic"
        "${config.services.grafana.settings.database.name}"
      ];
      ensureUsers = [
        {
          name = "atticd";
          ensurePermissions = { "DATABASE attic" = "ALL PRIVILEGES"; };
        }
        {
          name = "${config.services.grafana.settings.database.user}";
          ensurePermissions = { "DATABASE ${config.services.grafana.settings.database.name}" = "ALL PRIVILEGES"; };
        }
      ];
    };
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9001;
      retentionTime = "90d";
      globalConfig = {
        external_labels = { machine = "${config.networking.hostName}"; };
      };
      scrapeConfigs =
        let
          nodePort = toString config.services.prometheus.exporters.node.port;
          postgresPort = toString config.services.prometheus.exporters.postgres.port;
          nextcloudPort = toString config.services.prometheus.exporters.nextcloud.port;
          pvePort = toString config.services.prometheus.exporters.pve.port;
          labels = { machine = "${config.networking.hostName}"; };
        in
        [
          {
            job_name = "node";
            static_configs = [{ targets = [ "localhost:${nodePort}" ]; inherit labels; }];
          }
          {
            job_name = "postgres";
            static_configs = [{ targets = [ "localhost:${postgresPort}" ]; inherit labels; }];
          }
          {
            job_name = "proxmox";
            metrics_path = "/pve";
            params = { "target" = [ "wi.clansap.org" ]; };
            static_configs = [{ targets = [ "localhost:${toString pvePort}" ]; }];
          }
        ];
      exporters = {
        node = {
          enable = true;
          listenAddress = "localhost";
          port = 9101;
          enabledCollectors = [ "systemd" ];
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
          configFile = secrets.pve_prometheus.path;
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
        datasources.settings.datasources =
          let
            pointalphaPrometheusPort = toString hosts.pointalpha.config.services.prometheus.port;
            tankPrometheusPort = toString hosts.tank.config.services.prometheus.port;
          in
          [
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
    passwordFile = secrets.root_password_file.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM"
    ];
  };

  env.auto-upgrade.enable = false;

  security = {
    rtkit.enable = true;
    acme = {
      acceptTerms = true;
      defaults.email = "shawn@pointjig.de";
    };
  };

}
