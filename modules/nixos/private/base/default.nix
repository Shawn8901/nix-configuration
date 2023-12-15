{ inputs', config, pkgs, lib, ... }:
let inherit (lib) mkMerge mkDefault versionOlder optionalAttrs;
in {
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

  boot = mkMerge [
    {
      tmp.useTmpfs = mkDefault true;
      tmp.cleanOnBoot = true;
    }
    (optionalAttrs (!versionOlder config.system.nixos.release "23.11") {
      swraid.enable = mkDefault false;
    })
    # Remove with 23.11
    (lib.optionalAttrs (versionOlder config.system.nixos.release "23.11") {
      initrd.services.swraid.enable = mkDefault false;
    })
  ];

  services.lvm.enable = false;

  environment.sessionVariables.FLAKE =
    lib.mkDefault "github:shawn8901/nix-configuration";
  environment.systemPackages = with pkgs;
    [ git btop vim sops ] ++ [ inputs'.nh.packages.default ];

  services = {
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';

    udev.extraRules = lib.optionalString
      (builtins.elem "zfs" config.boot.supportedFilesystems) ''
        ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
      '';
  };
}