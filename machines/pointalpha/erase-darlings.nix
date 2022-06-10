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

  fileSystems."/var/lib/cups" = {
    device = "/persist/var/lib/cups";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/var/lib/systemd" = {
    device = "/persist/var/lib/systemd";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/var/lib/prometheus2" = {
    device = "/persist/var/lib/prometheus2";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/etc/nixos" = {
    device = "/persist/etc/nixos";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };
}
