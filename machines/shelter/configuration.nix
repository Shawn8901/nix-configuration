{
  self,
  self',
  config,
  fConfig,
  pkgs,
  inputs',
  ...
}: let
  uPkgs = inputs'.nixpkgs.legacyPackages;

  inherit (config.sops) secrets;
in {
  sops.secrets = {
    zrepl = {};
    prometheus-web-config = {
      owner = "prometheus";
      group = "prometheus";
    };
  };

  networking = {
    firewall = let
      zrepl = fConfig.shawn8901.zrepl.servePorts config.services.zrepl;
    in {
      allowedUDPPorts = [443];
      allowedTCPPorts = [80 443 9001] ++ zrepl;
    };
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "ens3";
          networkConfig.Address = ["78.128.127.235/25" "2a01:8740:1:e4::2cd3/64"];
          networkConfig.DNS = "8.8.8.8";
          networkConfig.Gateway = "78.128.127.129";
          routes = [
            {
              routeConfig = {
                Gateway = "2a01:8740:0001:0000:0000:0000:0000:0001";
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
    zfs.autoScrub = {
      enable = true;
      pools = ["zbackup"];
    };
    zrepl = {
      enable = true;
      package = uPkgs.zrepl;
      settings = {
        global = {
          monitoring = [
            {
              type = "prometheus";
              listen = ":9811";
              listen_freebind = true;
            }
          ];
        };
        jobs = [
          {
            name = "ztank_sink";
            type = "sink";
            root_fs = "zbackup/replica";
            serve = {
              type = "tls";
              listen = ":8888";
              ca = ../../files/public_certs/zrepl/tank.crt;
              cert = ../../files/public_certs/zrepl/shelter.crt;
              key = secrets.zrepl.path;
              client_cns = ["tank"];
            };
            recv = {placeholder = {encryption = "inherit";};};
          }
        ];
      };
    };

    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "status.shelter.pointjig.de" = {
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

    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      retentionTime = "90d";
      globalConfig = {
        external_labels = {machine = "${config.networking.hostName}";};
      };
      webConfigFile = secrets.prometheus-web-config.path;
      webExternalUrl = "https://status.shelter.pointjig.de";
    };
  };
  security = {
    auditd.enable = false;
    audit.enable = false;
  };
}
