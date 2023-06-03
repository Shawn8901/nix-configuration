{
  self,
  self',
  config,
  pkgs,
  inputs',
  ...
}: let
  hosts = self.nixosConfigurations;
  inherit (config.sops) secrets;
  inherit (inputs') attic;
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

  networking = let
    wireguardListenPort = 51820;
  in {
    firewall.allowedUDPPorts = [wireguardListenPort];
    nameservers = ["208.67.222.222" "208.67.220.220"];
    domain = "";
    useDHCP = true;
    wg-quick.interfaces = {
      wg0 = {
        listenPort = wireguardListenPort;
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
  systemd.services.wg-quick-wg0.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
  };
  services = {
    wireguard.reresolve-dns = {
      enable = true;
      package = self'.packages.wg-reresolve-dns;
    };
    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      retentionTime = "90d";
      globalConfig = {
        external_labels = {machine = "${config.networking.hostName}";};
      };
      scrapeConfigs = let
        pvePort = toString config.services.prometheus.exporters.pve.port;
      in [
        {
          job_name = "proxmox";
          metrics_path = "/pve";
          params = {"target" = ["wi.clansap.org"];};
          static_configs = [{targets = ["localhost:${toString pvePort}"];}];
        }
      ];
      exporters = {
        pve = {
          enable = true;
          listenAddress = "localhost";
          port = 9221;
          configFile = secrets.prometheus-pve.path;
        };
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

  shawn8901 = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
    };
    attic = {
      hostName = "cache.pointjig.de";
      package = attic.packages.attic;
      credentialsFile = secrets.attic-env.path;
    };
    grafana = {
      hostName = "grafana.pointjig.de";
      credentialsFile = secrets.grafana-env.path;
      datasources = [
        {
          name = "localhost";
          type = "prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}";
        }
        {
          name = "tank";
          type = "prometheus";
          url = "http://tank.fritz.box:${toString hosts.tank.config.services.prometheus.port}";
          basicAuth = true;
          withCredentials = true;
          basicAuthUser = "admin";
          secureJsonData.basicAuthPassword = "$__env{INTERNAL_PASSWORD}";
          jsonData.prometheusType = "Prometheus";
        }
        {
          name = "pointalpha";
          type = "prometheus";
          url = "http://pointalpha.fritz.box:${toString hosts.pointalpha.config.services.prometheus.port}";
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
}
