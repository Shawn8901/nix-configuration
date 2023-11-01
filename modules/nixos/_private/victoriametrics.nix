{ pkgs, lib, config, ... }:
let
  inherit (lib) types mkEnableOption mkOption mkDefault mkIf;

  cfg = config.shawn8901.victoriametrics;
in {
  options = {
    shawn8901.victoriametrics = {
      enable =
        mkEnableOption "Enables a preconfigured victoria metrics instance";
      hostname = mkOption {
        type = types.str;
        description = "full qualified hostname of the grafana instance";
      };
      port = mkOption {
        type = types.int;
        default = 8427;
      };
      credentialsFile = mkOption { type = types.path; };
      datasources = mkOption { type = types.listOf types.raw; };
    };
  };
  config = mkIf cfg.enable {
    systemd.services.vmauth = let
      authConfig = (pkgs.formats.yaml { }).generate "auth.yml" {
        users = [{
          username = "vm";
          password = "%{PASSWORD}";
          url_prefix =
            "http://${config.services.victoriametrics.listenAddress}";
        }];
      };
    in {
      description = "VictoriaMetrics basic auth proxy";
      after = [ "network.target" ];
      startLimitBurst = 5;
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 1;
        DynamicUser = true;
        EnvironmentFile = cfg.credentialsFile;
        ExecStart = ''
          ${pkgs.victoriametrics}/bin/vmauth \
            -auth.config=${authConfig} \
            -httpListenAddr=:${toString cfg.port}
        '';
      };
      wantedBy = [ "multi-user.target" ];
    };

    services = {
      nginx = {
        enable = mkDefault true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        virtualHosts = {
          "${cfg.hostname}" = {
            enableACME = true;
            forceSSL = true;
            http3 = true;
            kTLS = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString cfg.port}";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
      victoriametrics = {
        enable = true;
        retentionPeriod = 12;
        listenAddress = "localhost:8428";
      };
    };
  };
}
