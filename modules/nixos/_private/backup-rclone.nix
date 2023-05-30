{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.shawn8901.backup-rclone;

  inherit (lib) mkIf mkEnableOption mkOption types;
in {
  options = {
    shawn8901.backup-rclone = {
      enable = mkEnableOption "service to save personal files to dropbox";
      sourceDir = mkOption {
        type = types.str;
      };
      destDir = mkOption {
        type = types.str;
      };
    };
    config = mkIf cfg.enable {
      systemd = {
        services."backup-${cfg.sourceDir}" = {
          wants = ["network-online.target"];
          after = ["network-online.target"];
          description = "Copy nextcloud stuff to dropbox";
          serviceConfig = {
            Type = "oneshot";
            User = "shawn";
            ExecStart = "${lib.getExe pkgs.rclone} copy ${cfg.sourceDir} ${cfg.destDir}";
          };
        };
        timers."backup-${cfg.sourceDir}" = {
          wantedBy = ["timers.target"];
          partOf = ["backup-${cfg.sourceDir}"];
          timerConfig = {
            OnCalendar = ["daily"];
            Persistent = true;
            OnBootSec = "15min";
          };
        };
      };
    };
  };
}
