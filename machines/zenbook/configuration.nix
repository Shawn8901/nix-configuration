{
  self',
  self,
  pkgs,
  lib,
  config,
  fConfig,
  inputs,
  ...
}: let
  fPkgs = self'.packages;
  hosts = self.nixosConfigurations;
  inherit (config.sops) secrets;
in {
  sops.secrets = {
    zrepl = {restartUnits = ["zrepl.service"];};
    samba = {sopsFile = ./../../files/secrets-desktop.yaml;};
  };

  networking = {
    firewall = {
      logReversePathDrops = true;
      checkReversePath = false;
    };
    networkmanager = {
      enable = true;
      plugins = lib.mkForce [];
    };
    nftables.enable = true;
    hosts = {
      "134.255.226.114" = ["pointjig"];
      "2a05:bec0:1:16::114" = ["pointjig"];
      "78.128.127.235" = ["shelter"];
      "2a01:8740:1:e4::2cd3" = ["shelter"];
    };
    dhcpcd.enable = false;
    useNetworkd = false;
    useDHCP = false;
  };
  services.resolved.enable = false;
  systemd.network.wait-online.anyInterface = true;

  environment.systemPackages = with pkgs; [
    cifs-utils
    zenmonitor
  ];

  services = {
    udev = {
      packages = [pkgs.libmtp.out];
      extraRules = ''
      '';
    };
    openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
    };
    zfs = {
      trim.enable = true;
      autoScrub = {
        enable = true;
        pools = ["rpool"];
      };
    };
    printing = {
      enable = true;
      listenAddresses = ["localhost:631"];
      drivers = [pkgs.epson-escpr2];
    };
    zrepl = {
      enable = true;
      package = pkgs.zrepl;
      settings = {
        jobs = [
          {
            name = "zenbook";
            type = "push";
            filesystems = {"rpool/safe<" = true;};
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            connect = let
              zreplPort = fConfig.shawn8901.zrepl.servePorts hosts.tank.config.services.zrepl;
            in {
              type = "tls";
              address = "tank.fritz.box:${toString zreplPort}";
              ca = ../../files/public_certs/zrepl/tank.crt;
              cert = ../../files/public_certs/zrepl/zenbook.crt;
              key = secrets.zrepl.path;
              server_cn = "tank";
            };
            send = {
              encrypted = true;
              compressed = true;
            };
            pruning = {
              keep_sender = [
                {type = "not_replicated";}
                {
                  type = "grid";
                  grid = "1x3h(keep=all) | 2x6h | 30x1d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
              keep_receiver = [
                {
                  type = "grid";
                  grid = "1x3h(keep=all) | 2x6h | 30x1d | 6x30d | 1x365d";
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
        ];
      };
    };
    acpid.enable = true;
    upower.enable = true;
  };
  hardware = {
    sane.enable = true;
    keyboard.zsa.enable = true;
    asus-touchpad-numpad = {
      enable = true;
      package = fPkgs.asus-touchpad-numpad-driver;
      model = "ux433fa";
    };
  };
  systemd.tmpfiles.rules = ["d /media/nas 0750 shawn users -"];

  environment = {
    etc."samba/credentials_shawn".source = secrets.samba.path;
    sessionVariables = {
      FLAKE = "/home/shawn/dev/nix-configuration";
      WINEFSYNC = "1";
      WINEDEBUG = "-all";
    };
  };
  users.users.shawn = {
    extraGroups = ["video" "audio" "scanner" "lp" "networkmanager" "nixbld"];
  };
}
