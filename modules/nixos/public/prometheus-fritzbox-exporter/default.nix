{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf types literalExpression;
  cfg = config.services.prometheus-fritzbox-exporter;
in {
  options = {
    services.prometheus-fritzbox-exporter = {
      enable = mkEnableOption "fritz-exporter service";
      package = mkOption {
        type = types.package;
        default = pkgs.fritz-exporter;
        defaultText = literalExpression "pkgs.fritz-exporter";
        description = "Which package to use for fritz-exporter";
      };
      hostname = mkOption {
        type = types.str;
        default = "fritz.box";
      };
      port = mkOption {
        type = types.int;
        default = 9787;
      };
      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description =
          "env file to load, should contain FRITZ_USERNAME and FRITZ_USERNAME";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.prometheus-fritzbox-exporter = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      description = "Fetches data from fritzbox";
      environment = {
        FRITZ_PORT = toString cfg.port;
        FRITZ_HOSTNAME = cfg.hostname;
      };
      serviceConfig = {
        EnvironmentFile = cfg.environmentFile;
        DynamicUser = true;
        Restart = "always";
        ExecStart = "${lib.getExe pkgs.fritz-exporter}";
      };
    };
  };
}
