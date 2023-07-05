{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.shawn8901.nextcloud;
  inherit (lib) mkEnableOption mkDefault mkOption types literalExpression;
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
    networking.firewall = {
      allowedUDPPorts = [443];
      allowedTCPPorts = [80 443];
    };

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
        phpOptions = {
          "opcache.interned_strings_buffer" = "16";
          "opcache.enable" = "1";
          "opcache.save_comments" = "1";
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
        enable = mkDefault true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        virtualHosts."${cfg.hostName}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
        };
      };
      telegraf.extraConfig.inputs = {
        "http" = {
          urls = [
            "https://${config.services.nextcloud.hostName}/ocs/v2.php/apps/serverinfo/api/v1/info?format=json"
          ];
          method = "GET";
          username = "$NEXTCLOUD_USERNAME";
          password = "$NEXTCLOUD_PASSWORD";
          data_format = "json";
          success_status_codes = [200];
          timeout = "30s";
          interval = "60s";
          name_prefix = "nextcloud_";
        };
      };
    };
  };
}
