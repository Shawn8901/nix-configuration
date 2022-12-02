{ config, pkgs,inputs, ... }:
let
  system = pkgs.hostPlatform.system;
  uPkgs = inputs.nixpkgs.legacyPackages.${system};
in
{
  age.secrets = {
    zrepl_shelter = { file = ../../secrets/zrepl_shelter.age; };
  };

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
    zfs = {
      autoScrub.enable = true;
      autoScrub.pools = [ "zbackup" ];
    };
    zrepl = {
      enable = true;
      package = uPkgs.zrepl;
      settings = {
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
    fail2ban = {
      enable = true;
      maxretry = 5;
    };
    vnstat.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=100M
    '';
    acpid.enable = true;
  };
  security.auditd.enable = false;
  security.audit.enable = false;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  sound.enable = false;
  env.auto-upgrade.enable = true;
  env.user-config.enable = true;

  environment = {
    etc."zrepl/shelter.key".source = config.age.secrets.zrepl_shelter.path;
    etc."zrepl/shelter.crt".source = ../../public_certs/zrepl/shelter.crt;
    etc."zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
  };
}
