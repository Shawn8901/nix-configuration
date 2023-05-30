{
  config,
  pkgs,
  ...
}: let
  inherit (config.sops) secrets;
in {
  sops.secrets = {
    root = {};
    nextcloud-admin = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    prometheus-web-config = {
      owner = "prometheus";
      group = "prometheus";
    };
    prometheus-nextcloud = {
      owner = config.services.prometheus.exporters.nextcloud.user;
      group = config.services.prometheus.exporters.nextcloud.group;
    };
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "enp6s18";
          networkConfig.Address = ["134.255.226.115/28" "2a05:bec0:1:16::115/64"];
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
    };
  };

  services = {
    fstrim.enable = true;
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      virtualHosts = {
        "status.${config.services.nextcloud.hostName}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://localhost:9001";
          };
        };
      };
    };

    prometheus = let
      labels = {machine = "${config.networking.hostName}";};
    in {
      enable = true;
      listenAddress = "127.0.0.1";
      retentionTime = "90d";
      globalConfig = {
        external_labels = labels;
      };
      webConfigFile = secrets.prometheus-web-config.path;
      webExternalUrl = "https://status.${config.services.nextcloud.hostName}";
    };
  };
  security = {
    acme.defaults.email = "info@clansap.org";
    auditd.enable = false;
    audit.enable = false;
  };

  users.mutableUsers = false;
  users.users.root = {
    passwordFile = secrets.root.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
  };

  shawn8901 = {
    nextcloud = {
      enable = true;
      hostName = "next.clansap.org";
      adminPasswordFile = secrets.nextcloud-admin.path;
      home = "/var/lib/nextcloud";
      package = pkgs.nextcloud25;
      prometheus.passwordFile = secrets.prometheus-nextcloud.path;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
    };
  };
}
