{ self, config, pkgs, lib, hosts, helpers, ... }:

{
  imports = [
    ./hardware.nix
  ];

  age.secrets = {
    zrepl_backup = {
      file = ../../secrets/zrepl_backup.age;
    };
  };

  networking = {
    firewall =
      let
        zrepl = helpers.zreplServePorts config.services.zrepl;
      in
      {
        allowedUDPPorts = [ ];
        allowedUDPPortRanges = [ ];
        allowedTCPPorts = [ ] ++ zrepl;
        allowedTCPPortRanges = [ ];
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
          matchConfig.MACAddress = "fa:d1:59:0f:e0:aa";
          networkConfig = {
            Address = "5.182.206.58/23";
            DNS = "8.8.8.8";
            Gateway = "5.182.206.1";
          };
        };
      };
      wait-online.anyInterface = true;
    };
  };


  environment.systemPackages = with pkgs; [
    ncdu
  ];

  services = {
    xserver.enable = false;
    openssh.enable = true;
    resolved.enable = true;
    zfs = {
      autoScrub.enable = true;
      autoScrub.pools = [ "zbackup" ];
    };
    zrepl = {
      enable = true;
      settings = {
        jobs = [
          {
            name = "ztank_sink";
            type = "sink";
            root_fs = "zbackup/replica";

            serve = {
              type = "tls";
              listen = ":8888";
              ca = "/etc/zrepl/tank.crt";
              cert = "/etc/zrepl/backup.crt";
              key = "/etc/zrepl/backup.key";

              client_cns = [ "tank" ];
            };
            recv = {
              placeholder = { encryption = "inherit"; };
            };
          }
        ];
      };
    };
    fail2ban = {
      enable = true;
      maxretry = 5;
    };
    vnstat.enable = true;
  };
  security.auditd.enable = false;
  security.audit.enable = false;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  sound.enable = false;

  environment = {
    etc."zrepl/backup.key".source = config.age.secrets.zrepl_backup.path;
    etc."zrepl/backup.crt".source = ../../public_certs/zrepl/backup.crt;
    etc."zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
  };

  # remove bloatware (NixOS HTML file)
  documentation.nixos.enable = false;

  system.stateVersion = "22.05";
}
