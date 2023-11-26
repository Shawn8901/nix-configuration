{ config, lib, pkgs, ... }:
let
  cfg = config.shawn8901.postgresql;
  inherit (lib) mkEnableOption mkOption mkDefault mkIf types literalExpression;
in {
  options = {
    shawn8901.postgresql = {
      enable = mkEnableOption "Enables a preconfigured postgresql instance";
      package = mkOption {
        type = types.package;
        default = pkgs.postgresql_15;
      };
    };
  };

  config = mkIf cfg.enable {
    services = {
      postgresql = {
        enable = mkDefault true;
        package = cfg.package;
      };
      prometheus.exporters.postgres = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9187;
        runAsLocalSuperUser = true;
      };

      vmagent.prometheusConfig.scrape_configs = [{
        job_name = "postgres";
        static_configs = [{
          targets = [
            "localhost:${
              toString config.services.prometheus.exporters.postgres.port
            }"
          ];
        }];
      }];
    };
  };
}
