{ self, system, ... }:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.usb-backup;
  fPkgs = self.packages.${system};
in
{
  options = {
    services.usb-backup = {
      enable = lib.mkEnableOption "automatic backup to usb disk";
      mountPoint = lib.mkOption {
        type = lib.types.str;
        description = "Mountpoint of the usb disk";
      };
      backupPath = lib.mkOption {
        type = lib.types.str;
        description = "Path to backup";
      };
    };
  };
  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [ cifs-utils ];
    services = {
      udev.extraRules = ''
        SUBSYSTEM=="block", ACTION=="add", ATTRS{idVendor}=="04fc", ATTRS{idProduct}=="0c25", ATTR{partition}=="2", TAG+="systemd", ENV{SYSTEMD_WANTS}="usb-backup@%k.service"
      '';
    };

    systemd.services."usb-backup@" =
      let
        usbBackup =
          fPkgs.usb-backup.override { inherit (cfg) backupPath mountPoint; };
      in
      {
        description = "Backups ${cfg.backupPath} to usb hdd";
        serviceConfig = {
          Type = "simple";
          GuessMainPID = false;
          ExecStart = "${usbBackup}/bin/usb-backup %I";
        };
      };
  };
}
