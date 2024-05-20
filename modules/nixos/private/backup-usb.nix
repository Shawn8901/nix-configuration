{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.shawn8901.backup-usb;
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;
in
{
  options = {
    shawn8901.backup-usb = {
      enable = mkEnableOption "automatic backup to usb disk";
      mountPoint = mkOption {
        type = types.str;
        description = "Mountpoint of the usb disk";
      };
      backupPath = mkOption {
        type = types.str;
        description = "Path to backup";
      };
      package = mkOption { type = types.package; };
      device = {
        idVendor = mkOption { type = types.str; };
        idProduct = mkOption { type = types.str; };
        partition = mkOption { type = types.str; };
      };
    };
  };
  config = mkIf cfg.enable {
    # FIXME: Sound support shoud be configurable
    sound.enable = true;
    environment.systemPackages = [ pkgs.cifs-utils ];
    services.udev.extraRules = ''
      SUBSYSTEM=="block", ACTION=="add", ATTRS{idVendor}=="${cfg.device.idVendor}", ATTRS{idProduct}=="${cfg.device.idProduct}", ATTR{partition}=="${cfg.device.partition}", TAG+="systemd", ENV{SYSTEMD_WANTS}="backup-usb@%k.service"
    '';

    systemd.services."backup-usb@" =
      let
        backupUsb = cfg.package.override { inherit (cfg) backupPath mountPoint; };
      in
      {
        description = "Backups ${cfg.backupPath} to usb hdd";
        serviceConfig = {
          Type = "simple";
          GuessMainPID = false;
          ExecStart = "${lib.getExe backupUsb} %I";
        };
      };
  };
}
