{ self, config, lib, pkgs, ... }:

let
  cfg = config.services.nextcloud-notify_push;
in
{
  options = {
    services.nextcloud-notify_push = {
      enable = lib.mkEnableOption "Notify push";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.notify_push;
        defaultText = lib.literalExpression "pkgs.notify_push";
        description = "Which package to use for notify_push";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 7867;
        description = "Port to use for notify_push";
      };
    };
  };
  config = lib.mkIf cfg.enable {

    systemd.services."notify_push" = {
        description = "Push daemon for Nextcloud clients";
        documentation = [ "https://github.com/nextcloud/notify_push" ];
        after = [ "network.target" "postgresql.service" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          PORT = "${toString cfg.port}";
          NEXTCLOUD_URL = "https://${config.services.nextcloud.hostName}";
        };
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/notify_push ${config.services.nextcloud.datadir}/config/config.php";
          User = "nextcloud";
        };
      };

    services.nginx.virtualHosts.${config.services.nextcloud.hostName}.locations."^~ /push/" = {
      proxyPass = "http://127.0.0.1:${toString cfg.port}/";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };
}
