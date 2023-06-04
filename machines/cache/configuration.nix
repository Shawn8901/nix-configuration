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
    grafana-env = {
      owner = "grafana";
      group = "grafana";
    };
  };

  networking = {
    nameservers = ["208.67.222.222" "208.67.220.220"];
    domain = "";
    useDHCP = true;
  };

  services = {
    nginx.package = pkgs.nginxQuic;
    nginx.virtualHosts."influxdb.pointjig.de" = {
      enableACME = true;
      forceSSL = true;
      http3 = true;
      kTLS = true;
      locations."/" = {
        proxyPass = "http://${config.services.influxdb2.settings.http-bind-address}";
        recommendedProxySettings = true;
      };
    };
    influxdb2 = {
      enable = true;
      settings = {
        "reporting-disabled" = true;
        "http-bind-address" = "127.0.0.1:8086";
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
      enable = true;
      hostName = "cache.pointjig.de";
      package = attic.packages.attic;
      credentialsFile = secrets.attic-env.path;
    };
    grafana = {
      enable = true;
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
