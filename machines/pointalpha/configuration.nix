{
  self,
  self',
  pkgs,
  lib,
  config,
  fConfig,
  inputs',
  ...
}: let
  fPkgs = self'.packages;
  hosts = self.nixosConfigurations;

  inherit (config.sops) secrets;
  inherit (pkgs.hostPlatform) system;
in {
  sops.secrets = {
    zrepl = {};
    samba = {};
    samba-ela = {};
    prometheus-web-config = {
      owner = "prometheus";
      group = "prometheus";
    };
  };

  networking = {
    firewall = let
      zreplServePorts = fConfig.shawn8901.zrepl.servePorts config.services.zrepl;
    in {
      allowedTCPPorts = [config.services.prometheus.port] ++ zreplServePorts;
    };
    networkmanager = {
      enable = true;
      plugins = lib.mkForce [];
    };
    nftables.enable = true;
    hosts = {
      "192.168.11.31" = lib.attrNames hosts.tank.config.services.nginx.virtualHosts;
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
            filesystems = {"rpool/safe<" = true;};
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
              ca = "/etc/zrepl/tank.crt";
              cert = "/etc/zrepl/pointalpha.crt";
              key = "/etc/zrepl/pointalpha.key";
              client_cns = ["tank"];
            };
          }
        ];
      };
    };

    prometheus = let
      labels = {machine = "${config.networking.hostName}";};
      nodePort = config.services.prometheus.exporters.node.port;
      zfsPort = toString config.services.prometheus.exporters.zfs.port;
      smartctlPort = config.services.prometheus.exporters.smartctl.port;
      zreplPort = fConfig.shawn8901.zrepl.monitoringPorts config.services.zrepl;
    in {
      enable = true;
      listenAddress = "127.0.0.1";
      retentionTime = "90d";
      globalConfig = {
        external_labels = labels;
      };
      webConfigFile = secrets.prometheus-web-config.path;
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["localhost:${toString nodePort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "zfs";
          static_configs = [
            {
              targets = ["localhost:${zfsPort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "smartctl";
          static_configs = [
            {
              targets = ["localhost:${toString smartctlPort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "zrepl";
          static_configs = [
            {
              targets = ["localhost:${toString zreplPort}"];
              inherit labels;
            }
          ];
        }
      ];
      exporters = {
        node = {
          enable = true;
          listenAddress = "localhost";
          port = 9101;
          enabledCollectors = ["systemd"];
        };
        smartctl = {
          enable = true;
          listenAddress = "localhost";
          port = 9102;
          devices = ["/dev/sda"];
          maxInterval = "5m";
        };
        zfs = {
          enable = true;
          listenAddress = "localhost";
          port = 9134;
        };
      };
    };
    teamviewer.enable = true;
  };

  hardware = {
    sane.enable = true;
    keyboard.zsa.enable = true;
  };
  systemd.tmpfiles.rules = ["d /media/nas 0750 shawn users -"];

  programs = {
    ssh.startAgent = true;
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

  nix.settings = {
    keep-outputs = true;
    keep-derivations = true;
  };
  environment = {
    systemPackages = with pkgs; [
      cifs-utils
      zenmonitor
      nixpkgs-review
    ];
    etc = {
      "samba/credentials_ela".source = secrets.samba-ela.path;
      "samba/credentials_shawn".source = secrets.samba.path;
      "zrepl/pointalpha.key".source = secrets.zrepl.path;
      "zrepl/pointalpha.crt".source = ../../files/public_certs/zrepl/pointalpha.crt;
      "zrepl/tank.crt".source = ../../files/public_certs/zrepl/tank.crt;
    };
    sessionVariables = {
      FLAKE = "/home/shawn/dev/nix-configuration";
      WINEFSYNC = "1";
      WINEDEBUG = "-all";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N"];
  users.users.shawn.extraGroups = ["video" "audio" "libvirtd" "adbusers" "scanner" "lp" "networkmanager" "nixbld"];
}
