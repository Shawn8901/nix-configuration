{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.shawn8901.nextcloud;
  inherit (lib)
    mkEnableOption
    mkDefault
    mkMerge
    mkOption
    types
    literalExpression
    optionalAttrs
    versionOlder
    ;
in
{
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
      package = mkOption { type = types.package; };
      adminPasswordFile = mkOption { type = types.path; };
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
      allowedUDPPorts = [ 443 ];
      allowedTCPPorts = [
        80
        443
      ];
    };

    systemd = {
      services.nextcloud-setup.after = [ "postgresql.service" ];
      sockets.nextcloud-notify_push = {
        socketConfig = {
          ListenStream = config.services.nextcloud.notify_push.socketPath;
          RemoveOnStop = true;
          FlushPending = true;
        };
        wantedBy = [ "sockets.target" ];
      };
      services.nextcloud-notify_push.after = [ "nextcloud-notify_push.socket" ];
    };

    services = {
      nextcloud = mkMerge [
        {
          inherit (cfg) home hostName package;
          notify_push = {
            enable = cfg.notify_push.package != null;
            inherit (cfg.notify_push) package;
            bendDomainToLocalhost = true;
          };
          enable = true;
          configureRedis = true;
          https = true;
          autoUpdateApps.enable = true;
          autoUpdateApps.startAt = "Sun 14:00:00";
          maxUploadSize = "1G";
          config = {
            dbtype = "pgsql";
            dbuser = "nextcloud";
            dbhost = "/run/postgresql";
            dbname = "nextcloud";
            adminuser = "admin";
            adminpassFile = cfg.adminPasswordFile;
          };
          caching = {
            apcu = false;
            memcached = false;
          };
          phpOptions = {
            "opcache.interned_strings_buffer" = "32";
            "opcache.enable" = "1";
            "opcache.save_comments" = "1";
            "opcache.revalidate_freq" = "60";
          };
        }
        (optionalAttrs (versionOlder config.system.nixos.release "24.05") {
          extraOptions = {
            "overwrite.cli.url" = "https://${cfg.hostName}";
            default_phone_region = "DE";
            maintenance_window_start = mkDefault "1";
          };
        })
        (optionalAttrs (!versionOlder config.system.nixos.release "24.05") {
          settings = {
            "overwrite.cli.url" = "https://${cfg.hostName}";
            default_phone_region = "DE";
            maintenance_window_start = mkDefault "1";
          };
        })
      ];

      postgresql = {
        ensureDatabases = [ "${config.services.nextcloud.config.dbname}" ];
        ensureUsers = [
          {
            name = "${config.services.nextcloud.config.dbuser}";
            ensureDBOwnership = true;
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
      prometheus.exporters.nextcloud = {
        enable = cfg.prometheus.passwordFile != null;
        listenAddress = "localhost";
        port = 9205;
        url = "https://${config.services.nextcloud.hostName}";
        inherit (cfg.prometheus) passwordFile;
      };

      vmagent.prometheusConfig.scrape_configs =
        lib.mkIf config.services.prometheus.exporters.nextcloud.enable
          [
            {
              job_name = "nextcloud";
              static_configs = [
                { targets = [ "localhost:${toString config.services.prometheus.exporters.nextcloud.port}" ]; }
              ];
            }
          ];
    };
  };
}
