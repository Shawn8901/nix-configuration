{ self', self, config, flakeConfig, pkgs, lib, inputs, inputs', ... }:
let
  hosts = self.nixosConfigurations;
  fPkgs = self'.packages;

  inherit (config.sops) secrets;
in {
  imports = [ ./save-darlings.nix ];

  sops.secrets = {
    ssh-builder-key = { owner = "hydra-queue-runner"; };
    zfs-ztank-key = { };
    zrepl = { };
    ela = { };
    nextcloud-admin = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    prometheus-nextcloud = {
      owner = config.services.prometheus.exporters.nextcloud.user;
      group = config.services.prometheus.exporters.nextcloud.group;
    };
    prometheus-fritzbox = { };
    # GitHub access token is stored on all systems with group right for nixbld
    # but hydra-queue-runner has to be able to read them but can not be added
    # to nixbld (it then crashes as soon as its writing to the store).
    nix-gh-token-ro.mode = lib.mkForce "0777";
    github-write-token = {
      owner = "hydra-queue-runner";
      group = "hydra";
    };
    # mimir-env-dev = {
    #   file = ../../secrets/mimir-env-dev.age;
    #   owner = lib.mkIf config.services.stne-mimir.enable "mimir";
    #   group = lib.mkIf config.services.stne-mimir.enable "mimir";
    # };
    #  stfc-env-dev = {
    #   file = ../../secrets/stfc-env-dev.age;
    #   owner = lib.mkIf config.services.stfc-bot.enable "stfc-bot";
    #   group = lib.mkIf config.services.stfc-bot.enable "stfc-bot";
    # };
  };

  networking = {
    firewall.allowedTCPPorts =
      flakeConfig.shawn8901.zrepl.servePorts config.services.zrepl;
    hosts = {
      "127.0.0.1" = lib.attrNames config.services.nginx.virtualHosts;
      "::1" = lib.attrNames config.services.nginx.virtualHosts;
    };
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "eno1";
          networkConfig.DHCP = "yes";
          networkConfig.Domains = "fritz.box ~box ~.";
        };
      };
      wait-online = { ignoredInterfaces = [ "enp4s0" ]; };
    };
  };
  nix.settings.cores = 4;
  services = {
    openssh = {
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
        pools = [ "rpool" "ztank" ];
      };
    };
    zrepl = {
      enable = true;
      package = pkgs.zrepl;
      settings = {
        global = {
          monitoring = [{
            type = "prometheus";
            listen = ":9811";
            listen_freebind = true;
          }];
        };
        jobs = [
          {
            name = "rpool_safe";
            type = "snap";
            filesystems = { "rpool/safe<" = true; };
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            pruning = {
              keep = [
                {
                  type = "grid";
                  grid = "1x3h(keep=all) | 2x6h | 14x1d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
          {
            name = "pointalpha";
            type = "pull";
            root_fs = "ztank/backup/pointalpha";
            interval = "1h";
            connect = {
              type = "tls";
              address = "pointalpha:8888";
              ca = ../../files/public_certs/zrepl/pointalpha.crt;
              cert = ../../files/public_certs/zrepl/tank.crt;
              key = secrets.zrepl.path;
              server_cn = "pointalpha";
            };
            recv = { placeholder = { encryption = "inherit"; }; };
            pruning = {
              keep_sender = [
                { type = "not_replicated"; }
                {
                  type = "grid";
                  grid = "3x1d";
                  regex = "^zrepl_.*";
                }
              ];
              keep_receiver = [{
                type = "grid";
                grid = "7x1d(keep=all) | 3x30d";
                regex = "^zrepl_.*";
              }];
            };
          }
          {
            name = "zenbook_sink";
            type = "sink";
            root_fs = "ztank/backup/zenbook";
            serve = {
              type = "tls";
              listen = ":8888";
              ca = ../../files/public_certs/zrepl/zenbook.crt;
              cert = ../../files/public_certs/zrepl/tank.crt;
              key = secrets.zrepl.path;
              client_cns = [ "zenbook" ];
            };
            recv = { placeholder = { encryption = "inherit"; }; };
          }
          {
            name = "sapsrv01";
            type = "pull";
            root_fs = "ztank/backup/sapsrv01";
            interval = "1h";
            connect = {
              type = "tls";
              address = "sapsrv01.clansap.org:8888";
              ca = ../../files/public_certs/zrepl/sapsrv01.crt;
              cert = ../../files/public_certs/zrepl/tank.crt;
              key = secrets.zrepl.path;
              server_cn = "sapsrv01";
            };
            recv = { placeholder = { encryption = "inherit"; }; };
            pruning = {
              keep_receiver = [{
                type = "grid";
                grid = "7x1d(keep=all) | 3x30d";
                regex = "^auto_daily.*";
              }];
              keep_sender = [{
                type = "last_n";
                count = 10;
                regex = "^auto_daily.*";
              }];
            };
          }
          {
            name = "sapsrv02";
            type = "pull";
            root_fs = "ztank/backup/sapsrv02";
            interval = "1h";
            connect = {
              type = "tls";
              address = "sapsrv02.clansap.org:8888";
              ca = ../../files/public_certs/zrepl/sapsrv02.crt;
              cert = ../../files/public_certs/zrepl/tank.crt;
              key = secrets.zrepl.path;
              server_cn = "sapsrv02";
            };
            recv = { placeholder = { encryption = "inherit"; }; };
            pruning = {
              keep_receiver = [{
                type = "grid";
                grid = "7x1d(keep=all) | 3x30d";
                regex = "^auto_daily.*";
              }];
              keep_sender = [{
                type = "last_n";
                count = 10;
                regex = "^auto_daily.*";
              }];
            };
          }
          {
            name = "tank_data";
            type = "snap";
            filesystems = { "ztank/data<" = true; };
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            pruning = {
              keep = [
                {
                  type = "grid";
                  grid = "1x3h(keep=all) | 2x6h | 7x1d | 1x30d | 1x365d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
          {
            name = "tank_replica";
            type = "push";
            filesystems = { "ztank/replica<" = true; };
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            connect = let
              zreplPort = flakeConfig.shawn8901.zrepl.servePorts
                hosts.shelter.config.services.zrepl;
            in {
              type = "tls";
              address = "shelter.pointjig.de:${toString zreplPort}";
              ca = ../../files/public_certs/zrepl/shelter.crt;
              cert = ../../files/public_certs/zrepl/tank.crt;
              key = secrets.zrepl.path;
              server_cn = "shelter";
            };
            send = {
              encrypted = true;
              compressed = true;
            };
            pruning = {
              keep_sender = [
                { type = "not_replicated"; }
                {
                  type = "last_n";
                  count = 10;
                }
                {
                  type = "grid";
                  grid = "1x3h(keep=all) | 2x6h | 30x1d | 6x30d | 1x365d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
              keep_receiver = [{
                type = "grid";
                grid = "1x3h(keep=all) | 2x6h | 30x1d | 6x30d | 1x365d";
                regex = "^zrepl_.*";
              }];
            };
          }
        ];
      };
    };
    avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
    samba = {
      enable = true;
      openFirewall = true;
      extraConfig = ''
        logging = systemd
        min receivefile size = 16384
        use sendfile = true
        aio read size = 16384
        aio write size = 16384
      '';

      shares = {
        homes = {
          browseable = "no";
          writable = "no";
        };
        joerg = {
          path = "/media/joerg";
          "valid users" = "shawn";
          public = "no";
          writeable = "yes";
          printable = "no";
          "create mask" = 700;
          "directory mask" = 700;
          browseable = "yes";
        };
        ela = {
          path = "/media/daniela";
          "valid users" = "ela";
          public = "no";
          writeable = "yes";
          printable = "no";
          "create mask" = 700;
          "directory mask" = 700;
          browseable = "yes";
        };
        hopfelde = {
          path = "/media/hopfelde";
          public = "yes";
          writeable = "yes";
          printable = "no";
          browseable = "yes";
          available = "yes";
          "guest ok" = "yes";
          "valid users" = "nologin";
          "create mask" = 700;
          "directory mask" = 700;
        };
      };
    };
    smartd.enable = true;
    nextcloud = {
      recommendedDefaults = true;
      configureImaginary = true;
      configureMemories = true;
      configureMemoriesVaapi = true;
      configurePreviewSettings = true;
      configureRecognize = true;
    };
  };

  security = {
    auditd.enable = false;
    audit.enable = false;
  };
  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N"
    ];
    ela = {
      hashedPasswordFile = secrets.ela.path;
      isNormalUser = true;
      group = "users";
      uid = 1001;
      shell = pkgs.zsh;
    };
    nologin = {
      isNormalUser = false;
      isSystemUser = true;
      group = "users";
    };
    shawn = { extraGroups = [ "nextcloud" ]; };
    attic = {
      isNormalUser = false;
      isSystemUser = true;
      group = "users";
      home = "/var/lib/attic";
    };
  };
  services.prometheus-fritzbox-exporter = {
    enable = true;
    environmentFile = secrets.prometheus-fritzbox.path;
  };
  services.vmagent.prometheusConfig.scrape_configs = [{
    job_name = "fritzbox-exporter";
    static_configs = [{
      targets = [
        "localhost:${
          toString config.services.prometheus-fritzbox-exporter.port
        }"
      ];
    }];
  }];

  shawn8901 = {
    backup-rclone = {
      enable = true;
      sourceDir = "${config.services.nextcloud.home}/data/shawn/files/";
      destDir = "dropbox:";
    };
    backup-usb = {
      enable = true;
      package = fPkgs.backup-usb;
      device = {
        idVendor = "04fc";
        idProduct = "0c25";
        partition = "2";
      };
      mountPoint = "/media/usb_backup_ela";
      backupPath = "/media/daniela/";
    };
    shutdown-wakeup = {
      enable = true;
      package = fPkgs.rtc-helper;
      shutdownTime = "0:00:00";
      wakeupTime = "15:00:00";
    };
    nextcloud = {
      enable = true;
      hostName = "next.tank.pointjig.de";
      adminPasswordFile = secrets.nextcloud-admin.path;
      notify_push.package = pkgs.nextcloud-notify_push;
      home = "/persist/var/lib/nextcloud";
      package = pkgs.nextcloud28;
      prometheus.passwordFile = secrets.prometheus-nextcloud.path;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      dataDir = "/persist/var/lib/postgresql/16";
    };
    hydra = {
      enable = true;
      hostName = "hydra.pointjig.de";
      mailAdress = "hydra@pointjig.de";
      writeTokenFile = secrets.github-write-token.path;
      builder.sshKeyFile = secrets.ssh-builder-key.path;
      attic.enable = true;
      attic.package = inputs'.attic.packages.attic-client;
    };
    server.enable = true;
    managed-user.enable = true;
  };

  environment = { etc.".ztank_key".source = secrets.zfs-ztank-key.path; };
}
