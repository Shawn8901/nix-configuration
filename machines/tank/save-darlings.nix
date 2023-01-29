{
  lib,
  config,
  ...
}: {
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';

  environment.etc."machine-id".source = "/persist/etc/machine-id";
  environment.etc."/etc/nixos".source = "/persist/etc/nixos";

  fileSystems."/var/lib/systemd" = {
    device = "/persist/var/lib/systemd";
    options = ["bind" "noauto" "x-systemd.automount"];
  };

  fileSystems."/var/lib/prometheus2" = {
    device = "/persist/var/lib/prometheus2";
    options = ["bind" "noauto" "x-systemd.automount"];
  };

  fileSystems."/var/lib/hydra" = {
    device = "/persist/var/lib/hydra";
    options = ["bind" "noauto" "x-systemd.automount"];
  };

  fileSystems."/var/lib/samba" = {
    device = "/persist/var/lib/samba";
    options = ["bind" "noauto" "x-systemd.automount"];
  };

  fileSystems."/var/lib/vnstat" = {
    device = "/persist/var/lib/vnstat";
    options = ["bind" "noauto" "x-systemd.automount"];
  };

  fileSystems."/var/lib/fail2ban" = {
    device = "/persist/var/lib/fail2ban";
    options = ["bind" "noauto" "x-systemd.automount"];
  };

  fileSystems."/var/lib/acme" = {
    device = "/persist/var/lib/acme";
    options = ["bind" "noauto" "x-systemd.automount"];
  };

  fileSystems."/var/lib/nixos" = {
    device = "/persist/var/lib/nixos";
    noCheck = true;
    options = ["bind"];
  };
}
