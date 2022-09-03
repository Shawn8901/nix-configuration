{ lib, config, ... }:
{
  boot.initrd.systemd.services.initrd-rollback-root = {
    after = [ "zfs-import-rpool.service" ];
    wantedBy = [ "sysroot.mount" ];
    before = [ "sysroot.mount" ];
    description = "Rollback root fs";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.boot.zfs.package}/sbin/zfs rollback -r rpool/local/root@blank";
    };
  };

  environment.etc."machine-id".source = "/persist/etc/machine-id";

  fileSystems."/var/lib/bluetooth" = {
    device = "/persist/var/lib/bluetooth";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/var/db" = {
    device = "/persist/var/db";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/var/lib/NetworkManager" = {
    device = "/persist/var/lib/NetworkManager";
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

  fileSystems."/var/lib/upower" = {
    device = "/persist/var/lib/upower";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

  fileSystems."/etc/nixos" = {
    device = "/persist/etc/nixos";
    options = [ "bind" "noauto" "x-systemd.automount" ];
  };

}
