{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.shawn8901.shutdown-wakeup;

  wakeupPackage = cfg.package.override { inherit (cfg) wakeupTime; };

  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in
{
  options = {
    shawn8901.shutdown-wakeup = {
      enable = mkEnableOption "shutdown-wakeup service combo";
      shutdownTime = mkOption {
        type = types.str;
        description = "Time when shutdown timer starts";
      };
      package = mkOption { type = types.package; };
      wakeupTime = mkOption {
        type = types.str;
        description = "Time when device should wakeup again";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      services.sched-shutdown = {
        description = "Scheduled shutdown";
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.systemd}/bin/systemctl --force poweroff";
        };
      };
      timers.sched-shutdown = {
        wantedBy = [ "timers.target" ];
        partOf = [ "sched-shutdown.service" ];
        timerConfig.OnCalendar = [ "*-*-* ${cfg.shutdownTime}" ];
      };

      services.rtcwakeup = {
        description = "Automatic wakeup";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe wakeupPackage;
        };
      };
      timers.rtcwakeup = {
        wantedBy = [ "timers.target" ];
        partOf = [ "sched-shutdown.service" ];
        timerConfig = {
          Persistent = true;
          OnBootSec = "1min";
          OnCalendar = [ "*-*-* ${cfg.wakeupTime}" ];
        };
      };
    };
  };
}
