{ self, ... }:
{ config, lib, pkgs, ... }:

let cfg = config.services.usb-backup;
in {
  options = {
    services.backup-nextcloud = {
      enable = lib.mkEnableOption "service to save personal files to dropbox";
    };
    config = lib.mkIf cfg.enable {
      systemd = {
        services.backup-nextcloud = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          description = "Copy nextcloud stuff to dropbox";
          serviceConfig = {
            Type = "oneshot";
            User = "shawn";
            ExecStart =
              "${pkgs.rclone}/bin/rclone copy /var/lib/nextcloud/data/shawn/files/ dropbox:";
          };
        };
        timers.backup-nextcloud = {
          wantedBy = [ "timers.target" ];
          partOf = [ "backup-nextcloud.service" ];
          timerConfig = {
            OnCalendar = [ "daily" ];
            Persistent = true;
            OnBootSec = "15min";
          };
        };
      };
    };
  };
}
