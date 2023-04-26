{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.shawn8901.nextcloud;
  inherit (lib) mkEnableOption mkOption types literalExpression;
in {
  options = {
    shawn8901.nextcloud = {
      enable = mkEnableOption "Enables a preconfigured nextcloud instance";
      hostName = mkOption {
        type = types.str;
        description = "Hostname of the nextcloud instance";
      };
      home = mkOption {
        type = types.str;
        description = "Home directory of the nextcloud";
      };
      package = mkOption {
        type = types.package;
      };
      adminPasswordFile = mkOption {
        type = types.path;
      };
      notify_push.package = mkOption {
        type = types.nullOr types.package;
        default = null;
        defaultText = literalExpression "null";
      };
      prometheus.passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        defaultText = literalExpression "null";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.nextcloud-setup.after = ["postgresql.service"];
      services.nextcloud-notify_push = {
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };

    services = {
      nextcloud = {
        inherit (cfg) home hostName package;
        notify_push = {
          enable = cfg.notify_push.package != null;
          package = cfg.notify_push.package;
          bendDomainToLocalhost = true;
        };
        enable = true;
        configureRedis = true;
        enableBrokenCiphersForSSE = false;
        https = true;
        autoUpdateApps.enable = true;
        autoUpdateApps.startAt = "Sun 14:00:00";
        config = {
          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql";
          dbname = "nextcloud";
          adminuser = "admin";
          adminpassFile = cfg.adminPasswordFile;
          defaultPhoneRegion = "DE";
        };
        caching = {
          apcu = false;
          memcached = false;
        };
        extraOptions."overwrite.cli.url" = "https://${cfg.hostName}";
      };
      postgresql = {
        ensureDatabases = [
          "${config.services.nextcloud.config.dbname}"
        ];
        ensureUsers = [
          {
            name = "${config.services.nextcloud.config.dbuser}";
            ensurePermissions = {"DATABASE ${config.services.nextcloud.config.dbname}" = "ALL PRIVILEGES";};
          }
        ];
      };
      nginx = {
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."${cfg.hostName}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
        };
      };

      prometheus = {
        scrapeConfigs = let
          nextcloudPort = toString config.services.prometheus.exporters.nextcloud.port;
          labels = {machine = "${config.networking.hostName}";};
        in [
          {
            job_name = "nextcloud";
            static_configs = [
              {
                targets = ["localhost:${nextcloudPort}"];
                inherit labels;
              }
            ];
          }
        ];
        exporters.nextcloud = {
          enable = cfg.prometheus.passwordFile != null;
          listenAddress = "localhost";
          port = 9205;
          url = "https://${config.services.nextcloud.hostName}";
          inherit (cfg.prometheus) passwordFile;
        };
      };
    };
  };
}
