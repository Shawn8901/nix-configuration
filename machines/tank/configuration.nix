{ self, config, pkgs, lib, inputs, ... }:
let
  hosts = self.nixosConfigurations;
  secrets = config.age.secrets;
  inherit (inputs) stfc-bot mimir;
in
{
  imports = [ stfc-bot.nixosModule mimir.nixosModule ];

  age.secrets = {
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
      owner = "nextcloud-exporter";
      group = "nextcloud-exporter";
    };
    fritzbox_prometheus_file = {
      file = ../../secrets/fritzbox_prometheus.age;
      owner = "fritzbox-exporter";
      group = "fritzbox-exporter";
    };
    grafana_db_file = {
      file = ../../secrets/grafana_db.age;
      owner = "grafana";
      group = "grafana";
    };
    grafana_admin_password_file = {
      file = ../../secrets/grafana_admin_password_file.age;
      owner = "grafana";
      group = "grafana";
    };
    grafana_secret_key_file = {
      file = ../../secrets/grafana_secret_key_file.age;
      owner = "grafana";
      group = "grafana";
    };
    stfc-env-dev = {
      file = ../../secrets/stfc-env-dev.age;
      owner = "stfc-bot";
      group = "stfc-bot";
    };
    mimir-env-dev = {
      file = ../../secrets/mimir-env-dev.age;
      owner = "mimir";
      group = "mimir";
    };
    sms-shawn-passwd = { file = ../../secrets/sms-shawn-passwd.age; };
  };

  networking = {
    firewall =
      let zreplServePorts = inputs.zrepl.servePorts config.services.zrepl;
      in
      {
        allowedUDPPorts = [ 443 ];
        allowedUDPPortRanges = [ ];
        allowedTCPPorts = [ 80 443 ] ++ zreplServePorts;
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
          matchConfig.Name = "eno1";
          networkConfig.DHCP = "yes";
          networkConfig.Domains = "fritz.box ~box ~.";
        };
      };
      wait-online = { ignoredInterfaces = [ "enp4s0" ]; };
    };

    paths."nextcloud-secret-watcher" = {
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathModified = secrets.nextcloud_db_file.path;
      };
    };
    services."nextcloud-secret-watcher" = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "systemctl restart phpfpm-nextcloud.service";
      };
    };
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
      autoScrub.enable = true;
      autoScrub.pools = [ "rpool" "ztank" ];
    };
    zrepl = {
      enable = true;
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
                regex = "^auto_daily.*";
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
            send = { encrypted = true; };
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
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud25;
      https = true;
      hostName = "next.tank.pointjig.de";
      home = "/persist/var/lib/nextcloud";
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "Sun 14:00:00";
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        dbpassFile = secrets.nextcloud_db_file.path;
        adminuser = "admin";
        adminpassFile = secrets.nextcloud_admin_file.path;
        defaultPhoneRegion = "DE";
      };
      caching.apcu = true;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      dataDir = "/persist/var/lib/postgres/14";
      ensureDatabases = [
        "${config.services.nextcloud.config.dbname}"
        "${config.services.grafana.settings.database.name}"
        "stfcbot"
      ];
      ensureUsers = [
        {
          name = "${config.services.nextcloud.config.dbuser}";
          ensurePermissions = {
            "DATABASE ${config.services.nextcloud.config.dbname}" =
              "ALL PRIVILEGES";
          };
        }
        {
          name = "${config.services.grafana.settings.database.user}";
          ensurePermissions = {
            "DATABASE ${config.services.grafana.settings.database.name}" =
              "ALL PRIVILEGES";
          };
        }
        {
          name = "stfcbot";
          ensurePermissions = {
            "DATABASE stfcbot" = "ALL PRIVILEGES";
          };
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
        "${config.services.nextcloud.hostName}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
        };
        "${config.services.stne-mimir.domain}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
        };
        "${config.services.grafana.settings.server.domain}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
            proxyWebsockets = true;
          };
        };
      };
    };
    avahi.enable = true;
    avahi.nssmdns = true;
    samba = {
      enable = true;
      openFirewall = true;

      # You will still need to set up the user accounts to begin with:
      # $ sudo smbpasswd -a yourusername

      # This adds to the [global] section:
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
      retentionTime = "30d";
      globalConfig = {
        external_labels = { machine = "${config.networking.hostName}"; };
      };
      scrapeConfigs =
        let
          ownHostname = config.networking.hostName;
          pointalphaHostname = hosts.pointalpha.config.networking.hostName;
          nodePort = config.services.prometheus.exporters.node.port;
          zreplPort = (builtins.head
            (
              inputs.zrepl.monitoringPorts config.services.zrepl
            ));
          postgresPort = config.services.prometheus.exporters.postgres.port;
          nextcloudPort = config.services.prometheus.exporters.nextcloud.port;
          fritzboxPort = config.services.prometheus.exporters.fritzbox.port;
          prometheusPort = hosts.pointalpha.config.services.prometheus.port;
          labels = { machine = "${ownHostname}"; };
        in
        [
          {
            job_name = "node";
            static_configs = [{ targets = [ "localhost:${toString nodePort}" ]; inherit labels; }];
          }
          {
            job_name = "zrepl";
            static_configs = [{ targets = [ "localhost:${toString zreplPort}" ]; inherit labels; }];
          }
          {
            job_name = "postgres";
            static_configs = [{ targets = [ "localhost:${toString postgresPort}" ]; inherit labels; }];
          }
          {
            job_name = "nextcloud";
            static_configs = [{ targets = [ "localhost:${toString nextcloudPort}" ]; inherit labels; }];
          }
          {
            job_name = "fritzbox";
            static_configs = [{ targets = [ "localhost:${toString fritzboxPort}" ]; labels = { machine = "fritz.box"; }; }];
          }
          {
            job_name = "${pointalphaHostname}";
            honor_labels = true;
            metrics_path = "/federate";
            params = {
              "match[]" =
                [ "{machine='${pointalphaHostname}'}" ];
            };
            static_configs = [{
              targets = [ "${pointalphaHostname}:${toString prometheusPort}" ];
            }];
          }
        ];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9100;
        };
        fritzbox = {
          enable = true;
          extraFlags = [
            "-username prometheus"
            "-password ${lib.escapeShellArg "@${secrets.fritzbox_prometheus_file.path}"}"
          ];
        };
        nextcloud = {
          enable = true;
          port = 9205;
          url = "https://${config.services.nextcloud.hostName}";
          passwordFile = secrets.nextcloud_prometheus_file.path;
        };
        postgres = {
          enable = true;
          port = 9187;
          runAsLocalSuperUser = true;
        };
      };
    };
    grafana = {
      enable = true;
      dataDir = "/persist/var/lib/grafana";
      declarativePlugins = with pkgs.grafanaPlugins; [
        grafana-polystat-panel
        grafana-clock-panel
      ];
      settings = {
        server = rec {
          domain = "status.tank.pointjig.de";
          rootUrl = "https://${domain}/";
        };
        database = {
          type = "postgres";
          host = "/run/postgresql";
          user = "grafana";
          password = "$__file{${secrets.grafana_db_file.path}}";
        };
        security = {
          admin_password = "$__file{${secrets.grafana_admin_password_file.path}}";
          secret_key = "$__file{${secrets.grafana_secret_key_file.path}}";
        };
        analytics.reporting_enabled = false;
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [{
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${
              builtins.toString config.services.prometheus.port
            }";
          isDefault = true;
        }];
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
      SystemMaxUse=500M
      SystemMaxFileSize=100M
    '';
    stfc-bot = {
      enable = true;
      package = inputs.stfc-bot.packages.x86_64-linux.default;
      envFile = config.age.secrets.stfc-env-dev.path;
    };
    stne-mimir = {
      enable = true;
      domain = "mimir.tank.pointjig.de";
      clientPackage = inputs.mimir-client.packages.x86_64-linux.default;
      package = inputs.mimir.packages.x86_64-linux.default;
      envFile = config.age.secrets.mimir-env-dev.path;
      unixSocket = "/run/mimir-backend/mimir-backend.sock";
    };
  };
  security.rtkit.enable = true;
  security.acme = {
    acceptTerms = true;
    defaults.email = "shawn@pointjig.de";
  };
  security.auditd.enable = false;
  security.audit.enable = false;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
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

  environment = {
    etc.".ztank_key".source = secrets.ztank_key.path;
    etc."zrepl/tank.key".source = secrets.zrepl_tank.path;
    etc."zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
    etc."zrepl/pointalpha.crt".source = ../../public_certs/zrepl/pointalpha.crt;
    etc."zrepl/sapsrv01.crt".source = ../../public_certs/zrepl/sapsrv01.crt;
    etc."zrepl/sapsrv02.crt".source = ../../public_certs/zrepl/sapsrv02.crt;
    etc."zrepl/shelter.crt".source = ../../public_certs/zrepl/shelter.crt;
  };

  environment.systemPackages = [
      (pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        # XXX replace `<new version>` with the psqlSchema here
        export NEWDATA="/var/lib/postgresql/14"

        # XXX specify the postgresql package you'd like to upgrade to
        export NEWBIN="${pkgs.postgresql_14}/bin"

        export OLDDATA="${config.services.postgresql.dataDir}"
        export OLDBIN="${config.services.postgresql.package}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

        sudo -u postgres $NEWBIN/pg_upgrade \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir $OLDBIN --new-bindir $NEWBIN \
          "$@"
      '')
  ];
}
