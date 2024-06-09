{
  self,
  self',
  pkgs,
  lib,
  config,
  flakeConfig,
  inputs',
  ...
}:
let
  fPkgs = self'.packages;
  hosts = self.nixosConfigurations;

  inherit (config.sops) secrets;
in
{
  imports = [ ./save-darlings.nix ];

  sops.secrets = {
    zrepl = { };
    samba = { };
    samba-ela = { };
  };

  networking = {
    firewall.allowedTCPPorts = flakeConfig.shawn8901.zrepl.servePorts config.services.zrepl;
    networkmanager = {
      enable = true;
      plugins = lib.mkForce [ ];
    };
    nftables.enable = true;
    hosts = {
      "192.168.11.31" = lib.attrNames hosts.tank.config.services.nginx.virtualHosts;
      "134.255.226.114" = [ "pointjig" ];
      "2a05:bec0:1:16::114" = [ "pointjig" ];
      "78.128.127.235" = [ "shelter" ];
      "2a01:8740:1:e4::2cd3" = [ "shelter" ];
    };
    dhcpcd.enable = false;
    useNetworkd = false;
    useDHCP = false;
  };
  systemd.network.wait-online.anyInterface = true;

  services = {
    resolved.enable = false;
    udev.packages = [ pkgs.libmtp.out ];
    udev.extraRules = ''
      # Keymapp / Wally Flashing rules for the Moonlander and Planck EZ
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
      # Keymapp Flashing rules for the Voyager
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
    '';
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
        pools = [ "rpool" ];
      };
    };
    printing = {
      enable = true;
      listenAddresses = [ "localhost:631" ];
      drivers = [ pkgs.epson-escpr2 ];
    };
    zrepl = {
      enable = true;
      package = pkgs.zrepl;
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
            name = "pointalpha_safe";
            type = "source";
            filesystems = {
              "rpool/safe<" = true;
            };
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            send = {
              encrypted = false;
              compressed = true;
            };
            serve = {
              type = "tls";
              listen = ":8888";
              ca = ../../files/public_certs/zrepl/tank.crt;
              cert = ../../files/public_certs/zrepl/pointalpha.crt;
              key = secrets.zrepl.path;
              client_cns = [ "tank" ];
            };
          }
        ];
      };
    };
    teamviewer.enable = true;
    smartd = {
      enable = true;
      devices = [ { device = "/dev/nvme1"; } ];
    };
  };

  hardware = {
    sane = {
      enable = true;
      extraBackends = [
        (pkgs.epsonscan2.override {
          withNonFreePlugins = true;
          withGui = true;
        })
      ];
    };
    keyboard.zsa.enable = true;
  };
  systemd.tmpfiles.rules = [
    "d /media/nas 0750 shawn users -" # needed by own nas script for mounting
    "d /etc/exports.d 0750 root root" # needed by zfs to run 'zfs mount -a'
  ];

  programs = {
    ausweisapp = {
      enable = true;
      openFirewall = true;
    };
    partition-manager.enable = true;
  };

  virtualisation = {
    libvirtd = {
      enable = false;
      onBoot = "start";
      qemu.package = pkgs.qemu_kvm;
    };
  };

  nix.settings.keep-outputs = true;
  environment = {
    systemPackages = [ pkgs.cifs-utils ];
    etc = {
      "samba/credentials_ela".source = secrets.samba-ela.path;
      "samba/credentials_shawn".source = secrets.samba.path;
    };
    sessionVariables = {
      FLAKE = "/home/shawn/dev/nix-configuration";
      WINEFSYNC = "1";
      WINEDEBUG = "-all";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N"
  ];
  users.users.shawn.extraGroups = [
    "video"
    "audio"
    "scanner"
    "lp"
    "networkmanager"
  ];

  shawn8901 = {
    desktop.enable = true;
    managed-user.enable = true;
  };

}
