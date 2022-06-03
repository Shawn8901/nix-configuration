{ config, lib, pkgs, modulesPath, ... }:

{
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';

  fileSystems."/var/lib/bluetooth" = {
    device = "/persist/var/lib/bluetooth";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/var/lib/libvirt" = {
    device = "/persist/var/lib/libvirt";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/etc/nixos" = {
    device = "/persist/etc/nixos";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };
}
