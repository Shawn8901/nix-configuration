{ self, config, pkgs, lib, inputs, ... }:
let
  secrets = config.age.secrets;
  system = pkgs.hostPlatform.system;
in
{
  disabledModules = [ "services/monitoring/prometheus/default.nix" ];
  imports = [ ../../modules/nixos/overriden/prometheus.nix ];

  age.secrets = {
    ffm_nextcloud_db_file = {
      file = ../../secrets/ffm_nextcloud_db.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    ffm_root_password_file = {
      file = ../../secrets/ffm_root_password.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    prometheus_web_config = {
      file = ../../secrets/web_config_next_prometheus.age;
      owner = "prometheus";
      group = "prometheus";
    };
    nextcloud_prometheus_file = {
      file = ../../secrets/nextcloud_prometheus.age;
      owner = "nextcloud-exporter";
      group = "nextcloud-exporter";
    };
  };

  nix.gc.options = "--delete-older-than 3d";

  networking = {
    firewall = {
      allowedUDPPorts = [ 443 ];
      allowedUDPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 ];
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
          matchConfig.Name = "enp6s18";
          networkConfig.Address = [ "134.255.226.115/28" "2a05:bec0:1:16::115/64" ];
          networkConfig.DNS = "8.8.8.8";
          networkConfig.Gateway = "134.255.226.113";
          routes = [{
            routeConfig = {
              Gateway = "2a05:bec0:1:16::1";
              GatewayOnLink = "yes";
            };
          }];
        };
      };
    };
    services.nextcloud-setup.after = [ "postgresql.service" ];
  };

  services = {
    qemuGuest.enable = true;
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };
    resolved.enable = true;
    nextcloud = rec {
      enable = true;
      package = pkgs.nextcloud25;
      enableBrokenCiphersForSSE = false;
      https = true;
      hostName = "next.clansap.org";
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "Sun 14:00:00";
      phpOptions."opcache.interned_strings_buffer" = "16";
      phpOptions."opcache.enable" = "1";
      phpOptions."opcache.save_comments" = "1";
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        dbpassFile = secrets.ffm_nextcloud_db_file.path;
        adminuser = "admin";
        adminpassFile = secrets.ffm_root_password_file.path;
        trustedProxies = [ "134.255.226.115" "2a05:bec0:1:16::115" ]; # Fixme, setting the ipv6 here is somehow now what is wanted
        defaultPhoneRegion = "DE";
      };
      poolSettings = {
        "pm" = "dynamic";
        "pm.max_children" = 120;
        "pm.start_servers" = 12;
        "pm.min_spare_servers" = 6;
        "pm.max_spare_servers" = 24;
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
    nextcloud-notify_push = { enable = true; package = self.packages.${system}.notify_push; };
    redis.servers."nextcloud".enable = true;
    redis.servers."nextcloud".port = 6379;
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      ensureDatabases = [
        "${config.services.nextcloud.config.dbname}"
      ];
      ensureUsers = [
        {
          name = "${config.services.nextcloud.config.dbuser}";
          ensurePermissions = {
            "DATABASE ${config.services.nextcloud.config.dbname}" = "ALL PRIVILEGES";
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
        "status.${config.services.nextcloud.hostName}" = {
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
    fail2ban = {
      enable = true;
      maxretry = 5;
    };

    prometheus =
      let
        labels = { machine = "${config.networking.hostName}"; };
        nodePort = config.services.prometheus.exporters.node.port;
        postgresPort = config.services.prometheus.exporters.postgres.port;
        nextcloudPort = config.services.prometheus.exporters.nextcloud.port;
      in
      {
        enable = true;
        port = 9001;
        retentionTime = "30d";
        globalConfig = {
          external_labels = labels;
        };
        web_config_file = secrets.prometheus_web_config.path;
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [{ targets = [ "localhost:${toString nodePort}" ]; inherit labels; }];
          }
          {
            job_name = "postgres";
            static_configs = [{ targets = [ "localhost:${toString postgresPort}" ]; inherit labels; }];
          }
          {
            job_name = "nextcloud";
            static_configs = [{ targets = [ "localhost:${toString nextcloudPort}" ]; inherit labels; }];
          }
        ];
        exporters = {
          node = {
            enable = true;
            listenAddress = "localhost";
            port = 9100;
            enabledCollectors = [ "systemd" ];
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
            listenAddress = "127.0.0.1";
            port = 9187;
            runAsLocalSuperUser = true;
          };
        };
      };

    vnstat.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=100M
    '';
    acpid.enable = true;
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "info@clansap.org";
  };
  security.auditd.enable = false;
  security.audit.enable = false;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;

  env.auto-upgrade.enable = true;
  env.user-config.enable = false;

  users.mutableUsers = false;
  users.users.root = {
    passwordFile = secrets.ffm_root_password_file.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
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
