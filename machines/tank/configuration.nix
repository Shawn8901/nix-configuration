{ self, config, pkgs, lib, inputs, ... }:
let
  hosts = self.nixosConfigurations;
  secrets = config.age.secrets;
  system = pkgs.hostPlatform.system;
  # inherit (inputs) stfc-bot mimir;
in
{
  #imports = [ stfc-bot.nixosModules.default mimir.nixosModule ];

  age.secrets = {
    builder_ssh_priv = {
      file = ../../secrets/builder_ssh_priv.age;
      owner = "hydra-queue-runner";
    };
    ztank_key = { file = ../../secrets/ztank_key.age; };
    zrepl_tank = { file = ../../secrets/zrepl_tank.age; };
    ela_password_file = { file = ../../secrets/ela_password.age; };
    nextcloud_db_file = {
      file = ../../secrets/nextcloud_db.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    nextcloud_admin_file = {
      file = ../../secrets/nextcloud_admin.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    nextcloud_prometheus_file = {
      file = ../../secrets/nextcloud_prometheus.age;
      owner = config.services.prometheus.exporters.nextcloud.user;
      group = config.services.prometheus.exporters.nextcloud.group;
    };
    prometheus_web_config = {
      file = ../../secrets/prometheus_internal_web_config.age;
      owner = "prometheus";
      group = "prometheus";
    };
    fritzbox_prometheus_file = {
      file = ../../secrets/fritzbox_prometheus.age;
    };
    # GitHub access token is stored on all systems with group right for nixbld
    # but hydra-queue-runner has to be able to read them but can not be added
    # to nixbld (it then crashes as soon as its writing to the store).
    nix-gh-token.mode = lib.mkForce "0777";
    gh-write-token = {
      file = ../../secrets/gh-write-token.age;
      mode = "0777";
    };
    hydra-signing-key = {
      file = ../../secrets/hydra-signing-key.age;
      owner = "hydra";
      group = "hydra";
      mode = "0440";
    };
    nix-netrc = lib.mkForce {
      file = ../../secrets/nix-netrc-rw.age;
      group = "nixbld";
      mode = "0440";
    };
    # stfc-env-dev = {
    #   file = ../../secrets/stfc-env-dev.age;
    #   owner = lib.mkIf config.services.stfc-bot.enable "stfc-bot";
    #   group = lib.mkIf config.services.stfc-bot.enable "stfc-bot";
    # };
    # mimir-env-dev = {
    #   file = ../../secrets/mimir-env-dev.age;
    #   owner = lib.mkIf config.services.stne-mimir.enable "mimir";
    #   group = lib.mkIf config.services.stne-mimir.enable "mimir";
    # };
  };

  networking = {
    firewall =
      let zreplServePorts = inputs.zrepl.servePorts config.services.zrepl;
      in
      {
        allowedUDPPorts = [ 443 ];
        allowedUDPPortRanges = [ ];
        allowedTCPPorts = [ 80 443 9001 ] ++ zreplServePorts;
        allowedTCPPortRanges = [ ];
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
      wait-online = { ignoredInterfaces = [ "enp4s0" ]; };
    };
    services.nextcloud-setup.after = [ "postgresql.service" ];
    services.nextcloud-notify_push = {
      after = [ "redis-nextcloud.service" ];
      serviceConfig = { Restart = "on-failure"; RestartSec = "5s"; };
    };
    # TODO: Prepare a PR to fix/make it configurable that upstream
    services.prometheus-fritzbox-exporter.serviceConfig.EnvironmentFile = lib.mkForce secrets.fritzbox_prometheus_file.path;
  };

  services = {
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
    resolved.enable = true;
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
              ca = "/etc/zrepl/pointalpha.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";
              server_cn = "pointalpha";
            };
            recv = { placeholder = { encryption = "inherit"; }; };
            pruning = {
              keep_sender = [{
                type = "regex";
                regex = ".*";
              }];
              keep_receiver = [{
                type = "grid";
                grid = "7x1d(keep=all) | 3x30d";
                regex = "^zrepl_.*";
              }];
            };
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
            recv = { placeholder = { encryption = "inherit"; }; };
            pruning = {
              keep_sender = [{
                type = "regex";
                regex = ".*";
              }];
              keep_receiver = [{
                type = "grid";
                grid = "7x1d(keep=all) | 3x30d";
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
              ca = "/etc/zrepl/sapsrv02.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";
              server_cn = "sapsrv02";
            };
            recv = { placeholder = { encryption = "inherit"; }; };
            pruning = {
              keep_sender = [{
                type = "regex";
                regex = ".*";
              }];
              keep_receiver = [{
                type = "grid";
                grid = "7x1d(keep=all) | 3x30d";
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
            connect =
              let
                zreplPort = (builtins.head (inputs.zrepl.servePorts hosts.shelter.config.services.zrepl));
              in
              {
                type = "tls";
                address = "shelter.pointjig.de:${toString zreplPort}";
                ca = "/etc/zrepl/shelter.crt";
                cert = "/etc/zrepl/tank.crt";
                key = "/etc/zrepl/tank.key";
                server_cn = "shelter";
              };
            send = { encrypted = true; compressed = true; };
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
    nextcloud =
      let
        hostName = "next.tank.pointjig.de";
      in
      {
        inherit hostName;
        notify_push = {
          enable = true;
          package = self.packages.${system}.notify_push;
        };
        enable = true;
        package = pkgs.nextcloud25;
        enableBrokenCiphersForSSE = false;
        https = true;
        home = "/persist/var/lib/nextcloud";
        autoUpdateApps.enable = true;
        autoUpdateApps.startAt = "Sun 14:00:00";
        config = {
          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql";
          dbname = "nextcloud";
          adminuser = "admin";
          adminpassFile = secrets.nextcloud_admin_file.path;
          trustedProxies = [ "::1" "127.0.0.1" ];
          defaultPhoneRegion = "DE";
        };
        caching = {
          apcu = false;
          redis = true;
          memcached = false;
        };
        extraOptions.redis = {
          host = "127.0.0.1";
          port = 6379;
          dbindex = 0;
          timeout = 1.5;
        };
        extraOptions."overwrite.cli.url" = "https://${hostName}";
        extraOptions."memcache.local" = "\\OC\\Memcache\\Redis";
        extraOptions."memcache.locking" = "\\OC\\Memcache\\Redis";
      };
    redis.servers."nextcloud" = { enable = true; port = 6379; };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      dataDir = "/persist/var/lib/postgres/14";
      ensureDatabases = [
        "${config.services.nextcloud.config.dbname}"
        "stfcbot"
        "hydra"
      ];
      ensureUsers = [
        {
          name = "${config.services.nextcloud.config.dbuser}";
          ensurePermissions = { "DATABASE ${config.services.nextcloud.config.dbname}" = "ALL PRIVILEGES"; };
        }
        {
          name = "stfcbot";
          ensurePermissions = { "DATABASE stfcbot" = "ALL PRIVILEGES"; };
        }
        {
          name = "hydra";
          ensurePermissions = { "DATABASE hydra" = "ALL PRIVILEGES"; };
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
      virtualHosts = {
        "hydra.pointjig.de" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            recommendedProxySettings = true;
          };
        };
        "${config.services.nextcloud.hostName}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
        };
        # "${config.services.stne-mimir.domain}" = {
        #   enableACME = true;
        #   forceSSL = true;
        #   http3 = true;
        #   kTLS = true;
        # };
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
    fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [ "192.168.11.0/24" ];
    };
    vnstat.enable = true;
    smartd.enable = true;
    prometheus = {
      enable = true;
      port = 9001;
      retentionTime = "90d";
      globalConfig = {
        external_labels = { machine = "${config.networking.hostName}"; };
      };
      webConfigFile = secrets.prometheus_web_config.path;
      scrapeConfigs =
        let
          nodePort = toString config.services.prometheus.exporters.node.port;
          smartctlPort = toString config.services.prometheus.exporters.smartctl.port;
          zfsPort = toString config.services.prometheus.exporters.zfs.port;
          zreplPort = toString (builtins.head (inputs.zrepl.monitoringPorts config.services.zrepl));
          postgresPort = toString config.services.prometheus.exporters.postgres.port;
          nextcloudPort = toString config.services.prometheus.exporters.nextcloud.port;
          fritzboxPort = toString config.services.prometheus.exporters.fritzbox.port;
          pvePort = toString config.services.prometheus.exporters.pve.port;
          labels = { machine = "${config.networking.hostName}"; };
        in
        [
          {
            job_name = "node";
            static_configs = [{ targets = [ "localhost:${nodePort}" ]; inherit labels; }];
          }
          {
            job_name = "zfs";
            static_configs = [{ targets = [ "localhost:${zfsPort}" ]; inherit labels; }];
          }
          {
            job_name = "smartctl";
            static_configs = [{ targets = [ "localhost:${smartctlPort}" ]; inherit labels; }];
          }
          {
            job_name = "zrepl";
            static_configs = [{ targets = [ "localhost:${zreplPort}" ]; inherit labels; }];
          }
          {
            job_name = "postgres";
            static_configs = [{ targets = [ "localhost:${postgresPort}" ]; inherit labels; }];
          }
          {
            job_name = "nextcloud";
            static_configs = [{ targets = [ "localhost:${nextcloudPort}" ]; inherit labels; }];
          }
          {
            job_name = "fritzbox";
            static_configs = [{ targets = [ "localhost:${fritzboxPort}" ]; labels = { machine = "fritz.box"; }; }];
          }
          {
            job_name = "proxmox";
            metrics_path = "/pve";
            params = { "target" = [ "wi.clansap.org" ]; };
            static_configs = [{ targets = [ "localhost:${toString pvePort}" ]; }];
          }
        ];
      exporters = {
        node = {
          enable = true;
          listenAddress = "localhost";
          port = 9101;
          enabledCollectors = [ "systemd" ];
        };
        smartctl = {
          enable = true;
          listenAddress = "localhost";
          port = 9102;
          devices = [ "/dev/sda" ];
          maxInterval = "5m";
        };
        fritzbox = {
          enable = true;
          listenAddress = "localhost";
        };
        nextcloud = {
          enable = true;
          listenAddress = "localhost";
          port = 9205;
          url = "https://${config.services.nextcloud.hostName}";
          passwordFile = secrets.nextcloud_prometheus_file.path;
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
    # stfc-bot = {
    #   enable = false;
    #   package = inputs.stfc-bot.packages.x86_64-linux.default;
    #   envFile = config.age.secrets.stfc-env-dev.path;
    # };
    # stne-mimir = {
    #   enable = false;
    #   domain = "mimir.tank.pointjig.de";
    #   clientPackage = inputs.mimir-client.packages.x86_64-linux.default;
    #   package = inputs.mimir.packages.x86_64-linux.default;
    #   envFile = config.age.secrets.mimir-env-dev.path;
    #   unixSocket = "/run/mimir-backend/mimir-backend.sock";
    # };

    # FIXME: Move hydra stuff to a module, so that everything related to it, is stick together
    hydra =
      let
        atticPkg = inputs.attic.packages.${system}.attic-nixpkgs;
        upload_to_attic = pkgs.writeScriptBin "upload-to-attic" ''
          pathToPush=$(${pkgs.jq}/bin/jq -r '.outputs | .[] | .path' < $HYDRA_JSON)
          ${atticPkg}/bin/attic push nixos $pathToPush
        '';
        advance_branch = pkgs.writeScriptBin "advance_branch" ''
          echo $HYDRA_JSON
          cat $HYDRA_JSON
          set -x
          ${pkgs.curl}/bin/curl \
          -X POST \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: Bearer $(<${secrets.gh-write-token.path})" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          https://api.github.com/repos/shawn8901/nix-configuration/merges \
          -d '{"base":"main","head":"staging","commit_message":"Built flake update!"}'
          set +x
        '';
      in
      {
        enable = true;
        listenHost = "127.0.0.1";
        port = 3000;
        package = pkgs.hydra_unstable;
        minimumDiskFree = 2;
        minimumDiskFreeEvaluator = 5;
        hydraURL = "https://hydra.pointjig.de";
        notificationSender = "hydra@pointjig.de";
        useSubstitutes = true;
        extraConfig = ''
          evaluator_max_memory_size = 4096
          evaluator_initial_heap_size = ${toString (1 * 1024 * 1024 * 1024)}
          evaluator_workers = 4
          max_concurrent_evals = 2
          max_output_size = ${toString (4 * 1024 * 1024 * 1024)}
          max_db_connections = 150
          binary_cache_secret_key_file =  ${secrets.hydra-signing-key.path}

          <hydra_notify>
            <prometheus>
              listen_address = localhost
              port = 9199
            </prometheus>
          </hydra_notify>

          <runcommand>
            command = ${upload_to_attic}/bin/upload-to-attic
          </runcommand>
          <runcommand>
            job = *:staging:release
            command = ${advance_branch}/bin/advance_branch
          </runcommand>
        '';
      };
  };
  systemd.services.hydra-init.after = [ "network-online.target" ];
  nix.buildMachines =
    let
      sshUser = "root";
      sshKey = secrets.builder_ssh_priv.path;
    in
    [
      {
        hostName = "localhost";
        systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
        supportedFeatures = [ "gccarch-x86-64-v2" "gccarch-x86-64-v3" "benchmark" "big-parallel" "kvm" "nixos-test" ];
        maxJobs = 1;
        inherit sshUser sshKey;
      }
      {
        hostName = "pointalpha";
        systems = [ "x86_64-linux" "i686-linux" ];
        maxJobs = 1;
        supportedFeatures = [ "gccarch-x86-64-v2" "gccarch-x86-64-v3" "benchmark" "big-parallel" "kvm" "nixos-test" ];
        speedFactor = 2;
        inherit sshUser sshKey;
      }
    ];
  nix.settings.max-jobs = 4;
  nix.extraOptions = ''
    extra-allowed-uris = https://gitlab.com/api/v4/projects/rycee%2Fnmd https://git.sr.ht/~rycee/nmd https://github.com/zhaofengli/nix-base32.git https://github.com/zhaofengli/sea-orm
  '';
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N" ];


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
  env.user-config.enable = true;

  users.users = {
    ela = {
      passwordFile = secrets.ela_password_file.path;
      isNormalUser = true;
      group = "users";
      uid = 1001;
      shell = pkgs.zsh;
    };
    nologin = { isNormalUser = false; isSystemUser = true; group = "users"; };
    shawn = { extraGroups = [ "nextcloud" ]; };
  };
  nix.settings.netrc-file = lib.mkForce secrets.nix-netrc.path;

  environment = {
    noXlibs = true;
    etc.".ztank_key".source = secrets.ztank_key.path;
    etc."zrepl/tank.key".source = secrets.zrepl_tank.path;
    etc."zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
    etc."zrepl/pointalpha.crt".source = ../../public_certs/zrepl/pointalpha.crt;
    etc."zrepl/sapsrv01.crt".source = ../../public_certs/zrepl/sapsrv01.crt;
    etc."zrepl/sapsrv02.crt".source = ../../public_certs/zrepl/sapsrv02.crt;
    etc."zrepl/shelter.crt".source = ../../public_certs/zrepl/shelter.crt;

    systemPackages = [
      (pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        # XXX replace `<new version>` with the psqlSchema here
        export NEWDATA="/var/lib/postgresql/${pkgs.postgresql_15.psqlSchema}"

        # XXX specify the postgresql package you'd like to upgrade to
        export NEWBIN="${pkgs.postgresql_15}/bin"

        export OLDDATA="/var/lib/postgresql/${pkgs.postgresql_14.psqlSchema}"
        export OLDBIN="${pkgs.postgresql_14}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

        sudo -u postgres $NEWBIN/pg_upgrade \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir $OLDBIN --new-bindir $NEWBIN \
          "$@"
      '')
    ];
  };
}
