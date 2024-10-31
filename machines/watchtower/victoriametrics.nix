{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkEnableOption
    mkPackageOption
    mkOption
    mkDefault
    mkIf
    ;

  cfg = config.shawn8901.victoriametrics;
  yaml = pkgs.formats.yaml { };

  authConfig = yaml.generate "auth.yml" {
    users = [
      {
        username = "vm";
        password = "%{PASSWORD}";
        url_prefix = "http://${config.services.victoriametrics.listenAddress}";
      }
    ];
  };
in
{
  options = {
    shawn8901.victoriametrics = {
      enable = mkEnableOption "Enables a preconfigured victoria metrics instance";
      package = mkPackageOption pkgs "victoriametrics" { };
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
    systemd.services.vmauth = {
      description = "VictoriaMetrics basic auth proxy";
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        EnvironmentFile = cfg.credentialsFile;
        ExecStart = "${cfg.package}/bin/vmauth -auth.config=${authConfig} -httpListenAddr=:${toString cfg.port}";
      };
      wantedBy = [ "multi-user.target" ];
    };

    services = {
      nginx = {
        enable = mkDefault true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        virtualHosts."${cfg.hostname}" = {
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
      victoriametrics = {
        inherit (cfg) package;
        enable = true;
        retentionPeriod = "1y";
        listenAddress = "localhost:8428";
        extraOptions = [
          "-selfScrapeInterval=10s"
          "-selfScrapeInstance=${config.networking.hostName}"
        ];
      };
    };
  };
}
