{ self, config, lib, pkgs, ... }:

let

  cfg = config.services.shutdown-wakeup;
  system = pkgs.hostPlatform.system;
  fPkgs = self.packages.${system};
in
{
  options = {
    services.shutdown-wakeup = {
      enable = lib.mkEnableOption "shutdown-wakeup service combo";
      shutdownTime = lib.mkOption {
        type = lib.types.str;
        description = "Time when shutdown timer starts";
      };
      wakeupTime = lib.mkOption {
        type = lib.types.str;
        description = "Time when device should wakeup again";
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
        timerConfig = { OnCalendar = [ "*-*-* ${cfg.shutdownTime}" ]; };
      };

      services.rtcwakeup =
        let rtcHelper = fPkgs.rtc-helper.override { inherit (cfg) wakeupTime; };
        in
        {
          description = "Automatic wakeup";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${rtcHelper}/bin/rtc-helper";
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
