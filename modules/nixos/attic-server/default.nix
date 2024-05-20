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
    mkOption
    mkDefault
    mkIf
    ;

  cfg = config.shawn8901.attic;
in
{
  options = {
    shawn8901.attic = {
      enable = mkEnableOption "Enables a preconfigured attic instance";
      hostName = mkOption {
        type = types.str;
        description = "full qualified hostname of the attic instance";
      };
      package = mkOption { type = types.package; };
      credentialsFile = mkOption { type = types.path; };
    };
  };
  config = mkIf cfg.enable {
    networking.firewall = {
      allowedUDPPorts = [ 443 ];
      allowedTCPPorts = [
        80
        443
      ];
    };

    services = {
      nginx = {
        enable = mkDefault true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        clientMaxBodySize = "2G";
        virtualHosts = {
          "${cfg.hostName}" = {
            enableACME = true;
            forceSSL = true;
            http3 = false;
            http2 = false;
            kTLS = true;
            extraConfig = ''
              client_header_buffer_size 64k;
            '';
            locations."/" = {
              proxyPass = "http://127.0.0.1:8080";
              recommendedProxySettings = true;
            };
          };
        };
      };
      atticd = {
        inherit (cfg) package credentialsFile;

        enable = true;
        settings = {
          allowed-hosts = [ cfg.hostName ];
          api-endpoint = "https://${cfg.hostName}/";
          database = {
            url = "postgresql:///atticd?host=/run/postgresql";
            heartbeat = true;
          };
          chunking = {
            nar-size-threshold = 65536;
            min-size = 16384;
            avg-size = 65536;
            max-size = 262144;
          };
          compression.type = "zstd";
          garbage-collection = {
            interval = "12 hours";
            default-retention-period = "1 months";
          };
        };
      };
      postgresql = {
        ensureDatabases = [ "atticd" ];
        ensureUsers = [
          {
            name = "atticd";
            ensureDBOwnership = true;
          }
        ];
      };
    };
  };
}
