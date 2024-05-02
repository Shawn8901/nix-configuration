{
  inputs',
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkMerge
    mkDefault
    versionOlder
    optionalAttrs
    optionalString
    ;
in
{
  documentation = {
    doc.enable = false;
    nixos.enable = false;
    info.enable = false;
  };

  system.stateVersion = mkDefault "23.05";

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";
  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  boot = {
    tmp.useTmpfs = mkDefault true;
    tmp.cleanOnBoot = true;
    swraid.enable = mkDefault false;
    enableContainers = false;
  };

  environment.sessionVariables.FLAKE = lib.mkDefault "github:shawn8901/nix-configuration";
  environment.systemPackages = with pkgs; [
    vim
    sops
  ];

  services = mkMerge [
    {
      lvm.enable = false;
      journald.extraConfig = ''
        SystemMaxUse=100M
        SystemMaxFileSize=50M
      '';

      udev.extraRules = optionalString (config.boot.supportedFilesystems.zfs or false) ''
        ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
      '';
    }
    (optionalAttrs (!versionOlder config.system.nixos.release "24.05") {
      dbus.implementation = "broker";
    })
  ]

  ;
}
