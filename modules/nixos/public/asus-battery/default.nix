# https://github.com/NixOS/nixos-hardware/blob/master/asus/battery.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  charge-upto = pkgs.writeScriptBin "charge-upto" ''
    echo ''${0:-100} > /sys/class/power_supply/BAT?/charge_control_end_threshold
  '';
  cfg = config.hardware.asus.battery;
in
{
  options.hardware.asus.battery = {
    enable = lib.mkEnableOption "Enables the carge threshold module";
    chargeUpto = lib.mkOption {
      description = "Maximum level of charge for your battery, as a percentage.";
      default = 100;
      type = lib.types.int;
    };
    enableChargeUptoScript = lib.mkEnableOption "Whether to install charge-upto script";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.mkIf cfg.enableChargeUptoScript [ charge-upto ];

    systemd.services.battery-charge-threshold = {
      wantedBy = [
        "local-fs.target"
        "suspend.target"
      ];
      after = [
        "local-fs.target"
        "suspend.target"
      ];
      description = "Set the battery charge threshold to ${toString cfg.chargeUpto}%";
      startLimitIntervalSec = 5;
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        ExecStart = "${pkgs.runtimeShell} -c 'echo ${toString cfg.chargeUpto} > /sys/class/power_supply/BAT?/charge_control_end_threshold'";
      };
    };
  };
}
