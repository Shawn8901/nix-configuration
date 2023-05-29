{
  self,
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  hosts = self.nixosConfigurations;

  inherit (config.sops) secrets;
  inherit (pkgs.hostPlatform) system;
  inherit (inputs) mimir mimir-client stfc-bot;
in {
  imports = [
    mimir.nixosModules.default
    stfc-bot.nixosModules.default
    # https://github.com/NixOS/nixpkgs/pull/224274
    ../../modules/nixos/nextcloud.nix
  ];

  sops.secrets = {
    ssh-builder-key = {owner = "hydra-queue-runner";};
    zfs-ztank-key = {};
    zrepl = {};
    ela = {};
    nextcloud-admin = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    prometheus-nextcloud = {
      owner = config.services.prometheus.exporters.nextcloud.user;
      inherit (config.services.prometheus.exporters.nextcloud) group;
    };
    prometheus-web-config = {
      owner = "prometheus";
      group = "prometheus";
    };
    prometheus-fritzbox = {};
    # GitHub access token is stored on all systems with group right for nixbld
    # but hydra-queue-runner has to be able to read them but can not be added
    # to nixbld (it then crashes as soon as its writing to the store).
    nix-gh-token-ro.mode = lib.mkForce "0777";
    github-write-token = {
      owner = "hydra-queue-runner";
      group = "hydra";
    };
    hydra-signing-key = {
      owner = "hydra";
      group = "hydra";
      mode = "0440";
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

  nixpkgs.config.packageOverrides = pkgs: {
    udisks2 = pkgs.udisks2.override {
      btrfs-progs = null;
      nilfs-utils = null;
      xfsprogs = null;
      f2fs-tools = null;
    };
  };

  networking = {
    firewall = let
      zreplServePorts = inputs.zrepl.servePorts config.services.zrepl;
    in {
      allowedUDPPorts = [443];
      allowedUDPPortRanges = [];
      allowedTCPPorts = [80 443 9001] ++ zreplServePorts;
      allowedTCPPortRanges = [];
    };
    hosts = {
      "127.0.0.1" = lib.attrNames config.services.nginx.virtualHosts;
      "::1" = lib.attrNames config.services.nginx.virtualHosts;
    };
    networkmanager.enable = false;
    nftables.enable = true;
    dhcpcd.enable = false;
    useNetworkd = true;
    useDHCP = false;
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
      wait-online = {ignoredInterfaces = ["enp4s0"];};
    };
    # TODO: Prepare a PR to fix/make it configurable that upstream
    services.prometheus-fritzbox-exporter.serviceConfig.EnvironmentFile = lib.mkForce secrets.prometheus-fritzbox.path;
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
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
    resolved.enable = true;
    zfs = {
      trim.enable = true;
      autoScrub = {
        enable = true;
        pools = ["rpool" "ztank"];
      };
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
            name = "rpool_safe";
            type = "snap";
            filesystems = {"rpool/safe<" = true;};
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
              ca = "/etc/zrepl/pointalpha.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";
              server_cn = "pointalpha";
            };
            recv = {placeholder = {encryption = "inherit";};};
            pruning = {
              keep_sender = [
                {type = "not_replicated";}
                {
                  type = "grid";
                  grid = "3x1d";
                  regex = "^zrepl_.*";
                }
              ];
              keep_receiver = [
                {
                  type = "grid";
                  grid = "7x1d(keep=all) | 3x30d";
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
          {
            name = "zenbook_sink";
            type = "sink";
            root_fs = "ztank/backup/zenbook";
            serve = {
              type = "tls";
              listen = ":8888";
              ca = "/etc/zrepl/zenbook.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";
              client_cns = ["zenbook"];
            };
            recv = {placeholder = {encryption = "inherit";};};
          }
          {
            name = "sapsrv01";
            type = "pull";
            root_fs = "ztank/backup/sapsrv01";
            interval = "1h";
            connect = {
              type = "tls";
              address = "sapsrv01.clansap.org:8888";
              ca = "/etc/zrepl/sapsrv01.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";
              server_cn = "sapsrv01";
            };
            recv = {placeholder = {encryption = "inherit";};};
            pruning = {
              keep_receiver = [
                {
                  type = "grid";
                  grid = "7x1d(keep=all) | 3x30d";
                  regex = "^auto_daily.*";
                }
              ];
              keep_sender = [
                {
                  type = "last_n";
                  count = 10;
                  regex = "^auto_daily.*";
                }
              ];
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
              ca = "/etc/zrepl/sapsrv02.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";
              server_cn = "sapsrv02";
            };
            recv = {placeholder = {encryption = "inherit";};};
            pruning = {
              keep_receiver = [
                {
                  type = "grid";
                  grid = "7x1d(keep=all) | 3x30d";
                  regex = "^auto_daily.*";
                }
              ];
              keep_sender = [
                {
                  type = "last_n";
                  count = 10;
                  regex = "^auto_daily.*";
                }
              ];
            };
          }
          {
            name = "tank_data";
            type = "snap";
            filesystems = {"ztank/data<" = true;};
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
            filesystems = {"ztank/replica<" = true;};
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            connect = let
              zreplPort = builtins.head (inputs.zrepl.servePorts hosts.shelter.config.services.zrepl);
            in {
              type = "tls";
              address = "shelter.pointjig.de:${toString zreplPort}";
              ca = "/etc/zrepl/shelter.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";
              server_cn = "shelter";
            };
            send = {
              encrypted = true;
              compressed = true;
            };
            pruning = {
              keep_sender = [
                {type = "not_replicated";}
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
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      dataDir = "/persist/var/lib/postgresql/15";
      ensureDatabases = [
        "stfcbot"
        "hydra"
      ];
      ensureUsers = [
        {
          name = "stfcbot";
          ensurePermissions = {"DATABASE stfcbot" = "ALL PRIVILEGES";};
        }
        {
          name = "hydra";
          ensurePermissions = {"DATABASE hydra" = "ALL PRIVILEGES";};
        }
      ];
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      # "${config.services.stne-mimir.domain}" = {
      #   enableACME = true;
      #   forceSSL = true;
      #   http3 = true;
      #   kTLS = true;
      # };
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
    fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = ["192.168.11.0/24"];
    };
    vnstat.enable = true;
    smartd.enable = true;
    prometheus = {
      enable = true;
      port = 9001;
      retentionTime = "90d";
      globalConfig = {
        external_labels = {machine = "${config.networking.hostName}";};
      };
      webConfigFile = secrets.prometheus-web-config.path;
      scrapeConfigs = let
        nodePort = toString config.services.prometheus.exporters.node.port;
        smartctlPort = toString config.services.prometheus.exporters.smartctl.port;
        zfsPort = toString config.services.prometheus.exporters.zfs.port;
        zreplPort = toString (builtins.head (inputs.zrepl.monitoringPorts config.services.zrepl));
        postgresPort = toString config.services.prometheus.exporters.postgres.port;
        fritzboxPort = toString config.services.prometheus.exporters.fritzbox.port;
        pvePort = toString config.services.prometheus.exporters.pve.port;
        labels = {machine = "${config.networking.hostName}";};
      in [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["localhost:${nodePort}"];
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
              targets = ["localhost:${smartctlPort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "zrepl";
          static_configs = [
            {
              targets = ["localhost:${zreplPort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "postgres";
          static_configs = [
            {
              targets = ["localhost:${postgresPort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "fritzbox";
          static_configs = [
            {
              targets = ["localhost:${fritzboxPort}"];
              labels = {machine = "fritz.box";};
            }
          ];
        }
        {
          job_name = "proxmox";
          metrics_path = "/pve";
          params = {"target" = ["wi.clansap.org"];};
          static_configs = [{targets = ["localhost:${toString pvePort}"];}];
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
        fritzbox = {
          enable = true;
          listenAddress = "localhost";
        };
        postgres = {
          enable = true;
          listenAddress = "localhost";
          port = 9187;
          runAsLocalSuperUser = true;
        };
        zfs = {
          enable = true;
          listenAddress = "localhost";
          port = 9134;
        };
      };
    };
    shutdown-wakeup = {
      enable = true;
      shutdownTime = "0:00:00";
      wakeupTime = "15:00:00";
    };
    usb-backup = {
      enable = true;
      mountPoint = "/media/usb_backup_ela";
      backupPath = "/media/daniela/";
    };
    backup-nextcloud.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';
    # stne-mimir = {
    #   enable = false;
    #   domain = "mimir.tank.pointjig.de";
    #   clientPackage = inputs.mimir-client.packages.x86_64-linux.default;
    #   package = inputs.mimir.packages.x86_64-linux.default;
    #   envFile = config.age.secrets.mimir-env-dev.path;
    #   unixSocket = "/run/mimir-backend/mimir-backend.sock";
    # };
    # stfc-bot = {
    #   enable = false;
    #   package = stfc-bot.packages.x86_64-linux.default;
    #   envFile = config.age.secrets.stfc-env-dev.path;
    # };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "shawn@pointjig.de";
  };
  security.auditd.enable = false;
  security.audit.enable = false;
  hardware = {
    pulseaudio.enable = false;
    bluetooth.enable = false;
  };

  users.users = {
    root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N"];
    ela = {
      passwordFile = secrets.ela.path;
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
    shawn = {extraGroups = ["nextcloud"];};
    attic = {
      isNormalUser = false;
      isSystemUser = true;
      group = "users";
      home = "/var/lib/attic";
    };
  };
  shawn8901 = {
    auto-upgrade.enable = true;
    nextcloud = {
      enable = true;
      hostName = "next.tank.pointjig.de";
      notify_push.package = self.packages.${system}.notify_push;
      adminPasswordFile = secrets.nextcloud-admin.path;
      home = "/persist/var/lib/nextcloud";
      package = pkgs.nextcloud26;
      prometheus.passwordFile = secrets.prometheus-nextcloud.path;
    };
    hydra = {
      enable = true;
      hostName = "hydra.pointjig.de";
      mailAdress = "hydra@pointjig.de";
      writeTokenFile = secrets.github-write-token.path;
      builder.sshKeyFile = secrets.ssh-builder-key.path;
      attic.package = inputs.attic.packages.${system}.attic-client;
    };
    user-config.enable = true;
  };

  environment = {
    noXlibs = true;
    etc = {
      ".ztank_key".source = secrets.zfs-ztank-key.path;
      "zrepl/tank.key".source = secrets.zrepl.path;
      "zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
      "zrepl/pointalpha.crt".source = ../../public_certs/zrepl/pointalpha.crt;
      "zrepl/sapsrv01.crt".source = ../../public_certs/zrepl/sapsrv01.crt;
      "zrepl/sapsrv02.crt".source = ../../public_certs/zrepl/sapsrv02.crt;
      "zrepl/shelter.crt".source = ../../public_certs/zrepl/shelter.crt;
      "zrepl/zenbook.crt".source = ../../public_certs/zrepl/zenbook.crt;
    };
  };
}
