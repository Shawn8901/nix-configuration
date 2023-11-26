{ config, lib, pkgs, ... }:
let
  cfg = config.shawn8901.backup-rclone;

  inherit (lib) mkIf mkEnableOption mkOption types;
in {
  options = {
    shawn8901.backup-rclone = {
      enable = mkEnableOption "service to save personal files to dropbox";
      sourceDir = mkOption { type = types.str; };
      destDir = mkOption { type = types.str; };
    };
  };
  config = mkIf cfg.enable {
    systemd = let
      serviceName =
        cfg.sourceDir; # "backup-${builtins.replaceStrings ["/"] ["-"] safePath}";
    in {
      services.${serviceName} = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        description = "Copy nextcloud stuff to dropbox";
        serviceConfig = {
          Type = "oneshot";
          User = "shawn";
          ExecStart =
            "${lib.getExe pkgs.rclone} copy ${cfg.sourceDir} ${cfg.destDir}";
        };
      };
      timers.${serviceName} = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = [ "daily" ];
          Persistent = true;
          OnBootSec = "15min";
        };
      };
    };
  };
}
