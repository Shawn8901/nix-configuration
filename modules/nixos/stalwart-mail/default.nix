{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkPackageOption
    types
    ;

  cfg = config.services.stalwart-mail;
  configFormat = pkgs.formats.toml { };

  configFile = configFormat.generate "stalwart-mail.toml" cfg.settings;

  listenerOpts = name: port: tls: {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    port = mkOption {
      type = types.port;
      default = port;
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
    };

    listenAddress = mkOption {
      type = types.str;
      default = "[::]";
    };

    tls = mkOption {
      type = types.bool;
      default = tls;
    };
  };
in
{
  options.services.stalwart-mail = {
    enable = mkEnableOption "Enables Stalwart service";

    package = mkPackageOption pkgs "stalwart-mail" { };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/stalwart-mail";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file as defined in {manpage}`systemd.exec(5)`.";
    };
    fallbackAdminSecret = mkOption {
      type = types.str;
      default = "%{env:FALLBACK_ADMIN_PASSWORD}%";
    };

    settings = mkOption {
      inherit (configFormat) type;
      default = { };
      description = ''
        Configuration options for the Stalwart email server.
        See <https://stalw.art/docs/category/configuration> for available options.

        By default, the module is configured to store everything locally.
      '';
    };

    hostname = mkOption {
      type = types.str;
      default = config.networking.hostName;
    };

    smtp = listenerOpts "smtp" 25 false;
    submissions = listenerOpts "submissions" 465 true;
    imap = listenerOpts "imap" 993 true;
    http = listenerOpts "http" 443 true;
    managesieve = listenerOpts "managesieve" 4190 false;

    spamfilter = mkOption {
      type = types.bool;
      default = true;
    };

    store = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            freeformType = configFormat.type;
            options = {
              type = mkOption {
                type = types.enum [
                  "rocksdb"
                  "foundationdb"
                  "postgresql"
                  "mysql"
                  "sqlite"
                ];
              };
            };
          }
        )
      );
      default = {
        rocksdb = {
          type = "rocksdb";
          path = "${cfg.dataDir}/data";
        };
      };
    };

    storage = {
      data = mkOption {
        type = types.str;
        default = "rocksdb";
      };
      fts = mkOption {
        type = types.str;
        default = "rocksdb";
      };
      blob = mkOption {
        type = types.str;
        default = "rocksdb";
      };
      lookup = mkOption {
        type = types.str;
        default = "rocksdb";
      };
      directory = mkOption {
        type = types.str;
        default = "internal";
      };
    };

    directory = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            freeformType = configFormat.type;
            options = {
              type = mkOption {
                type = types.enum [
                  "internal"
                  "sql"
                  "ldap"
                  "memory"
                  "imap"
                  "smtp"
                  "lmtp"
                ];
              };
            };
          }
        )
      );
      default = {
        internal = {
          type = "internal";
          store = "rocksdb";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.lists.flatten [
      (lib.lists.optional (cfg.smtp.enable && cfg.smtp.openFirewall) cfg.smtp.port)
      (lib.lists.optional (cfg.submissions.enable && cfg.submissions.openFirewall) cfg.submissions.port)
      (lib.lists.optional (cfg.imap.enable && cfg.imap.openFirewall) cfg.imap.port)
      (lib.lists.optional (cfg.http.enable && cfg.http.openFirewall) cfg.http.port)
      (lib.lists.optional (cfg.managesieve.enable && cfg.managesieve.openFirewall) cfg.managesieve.port)
    ];

    services.stalwart-mail.settings = {
      config.resource = {
        spam-filter = lib.mkIf cfg.spamfilter (
          lib.mkDefault "file://${cfg.package}/etc/stalwart/spamfilter.toml"
        );
        webadmin = lib.mkDefault "file://${cfg.package}/share/web/webadmin.zip";
      };

      tracer.journal = {
        type = "journal";
        level = lib.mkDefault "info";
        enable = lib.mkDefault true;
      };

      lookup.default.hostname = cfg.hostname;

      resolver.public-suffix = lib.mkDefault [
        "file://${pkgs.publicsuffix-list}/share/publicsuffix/public_suffix_list.dat"
      ];

      server.listener =
        let
          mkListener =
            config: protocol:
            lib.mkIf config.enable ({
              inherit protocol;
              bind = [ "${config.listenAddress}:${toString config.port}" ];
              tls.implicit = config.tls;
            });
        in
        {
          smtp = mkListener cfg.smtp "smtp";
          submissions = mkListener cfg.submissions "smtp";
          imap = mkListener cfg.imap "imap";
          managesieve = mkListener cfg.managesieve "managesieve";
          http = mkListener cfg.http "http";
        };

      inherit (cfg) store storage directory;

      authentication.fallback-admin = {
        user = "admin";
        secret = cfg.fallbackAdminSecret;
      };
    };

    systemd.services.stalwart-mail = {
      wantedBy = [ "multi-user.target" ];
      after = [
        "local-fs.target"
        "network.target"
      ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/stalwart-mail --config=${configFile}";
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) [ cfg.environmentFile ];

        # Base from template resources/systemd/stalwart-mail.service
        Type = "simple";
        LimitNOFILE = 65536;
        KillMode = "process";
        KillSignal = "SIGINT";
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "stalwart-mail";

        DynamicUser = true;
        User = "stalwart-mail";
        StateDirectory = "stalwart-mail";

        # Bind standard privileged ports
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

        # Hardening
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateUsers = false; # incompatible with CAP_NET_BIND_SERVICE
        ProcSubset = "pid";
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        UMask = "0077";
      };
    };

    # Make admin commands available in the shell
    environment.systemPackages = [ cfg.package ];
  };
}
