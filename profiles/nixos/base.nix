{
  inputs',
  config,
  pkgs,
  lib,
  ...
}: {
  documentation = {
    doc.enable = false;
    nixos.enable = false;
    info.enable = false;
    man = {
      enable = lib.mkDefault true;
      generateCaches = lib.mkDefault true;
    };
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  boot.tmp.cleanOnBoot = true;

  services.lvm.enable = false;

  environment.sessionVariables.FLAKE = lib.mkDefault "github:shawn8901/nix-configuration";
  environment.systemPackages = with pkgs;
    [
      git
      htop
      nano
      vim
      sops
    ]
    ++ [inputs'.nh.packages.default];

  services = {
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';

    udev.extraRules = lib.optionalString (builtins.elem "zfs" config.boot.supportedFilesystems) ''
      ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
    '';
  };
}
