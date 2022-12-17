{ config, pkgs, inputs, ... }:
let
  system = pkgs.hostPlatform.system;
  uPkgs = inputs.nixpkgs.legacyPackages.${system};
  secrets = config.age.secrets;
in
{
  # FIXME: Remove with 23.05
  disabledModules = [ "services/monitoring/prometheus/default.nix" ];
  imports = [ ../../modules/nixos/overriden/prometheus.nix ];

  age.secrets = {
    zrepl_shelter = { file = ../../secrets/zrepl_shelter.age; };
    prometheus_web_config = {
      file = ../../secrets/web_config_public_prometheus.age;
      owner = "prometheus";
      group = "prometheus";
    };
  };

  nix.gc.options = "--delete-older-than 3d";

  networking = {
    firewall =
      let zrepl = inputs.zrepl.servePorts config.services.zrepl;
      in {
        allowedUDPPorts = [ ];
        allowedUDPPortRanges = [ ];
        allowedTCPPorts = [ ] ++ zrepl;
        allowedTCPPortRanges = [ ];
        logRefusedConnections = false;
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
          matchConfig.Name = "ens3";
          networkConfig.Address =
            [ "78.128.127.235/25" "2a01:8740:1:e4::2cd3/64" ];
          networkConfig.DNS = "8.8.8.8";
          networkConfig.Gateway = "78.128.127.129";
          routes = [{
            routeConfig = {
              Gateway = "2a01:8740:0001:0000:0000:0000:0000:0001";
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
    zfs.autoScrub = {
      enable = true;
      pools = [ "zbackup" ];
    };
    zrepl = {
      enable = true;
      package = uPkgs.zrepl;
      settings = {
        global = {
          monitoring = [{
            type = "prometheus";
            listen = ":9811";
            listen_freebind = true;
          }];
        };
        jobs = [{
          name = "ztank_sink";
          type = "sink";
          root_fs = "zbackup/replica";
          serve = {
            type = "tls";
            listen = ":8888";
            ca = "/etc/zrepl/tank.crt";
            cert = "/etc/zrepl/shelter.crt";
            key = "/etc/zrepl/shelter.key";
            client_cns = [ "tank" ];
          };
          recv = { placeholder = { encryption = "inherit"; }; };
        }];
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


    prometheus =
      let
        labels = { machine = "${config.networking.hostName}"; };
        nodePort = config.services.prometheus.exporters.node.port;
        zreplPort = (builtins.head (inputs.zrepl.monitoringPorts config.services.zrepl));
      in
      {
        enable = true;
        port = 9001;
        retentionTime = "30d";
        globalConfig = {
          external_labels = labels;
        };
        webConfigFile = secrets.prometheus_web_config.path;
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [{ targets = [ "localhost:${toString nodePort}" ]; inherit labels; }];
          }
          {
            job_name = "zrepl";
            static_configs = [{ targets = [ "localhost:${toString zreplPort}" ]; inherit labels; }];
          }
        ];
        exporters = {
          node = {
            enable = true;
            listenAddress = "localhost";
            port = 9101;
            enabledCollectors = [ "systemd" ];
          };
        };
      };

    fail2ban = {
      enable = true;
      maxretry = 5;
    };
    vnstat.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';
    acpid.enable = true;
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "shawn@pointjig.de";
  };
  security.auditd.enable = false;
  security.audit.enable = false;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  sound.enable = false;
  env.auto-upgrade.enable = true;
  env.user-config.enable = true;

  environment = {
    noXlibs = true;
    etc."zrepl/shelter.key".source = config.age.secrets.zrepl_shelter.path;
    etc."zrepl/shelter.crt".source = ../../public_certs/zrepl/shelter.crt;
    etc."zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
  };
}
