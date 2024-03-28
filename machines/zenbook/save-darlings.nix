{ lib, config, ... }: {
  # boot.initrd.postDeviceCommands = lib.mkAfter ''
  #   zfs rollback -r rpool/local/root@blank
  # '';

  environment.etc."machine-id".source = "/persist/etc/machine-id";
  environment.etc."nixos".source = "/persist/etc/nixos";

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';

  fileSystems = {

    "/var/lib/bluetooth" = {
      device = "/persist/var/lib/bluetooth";
      options = [ "bind" "noauto" "x-systemd.automount" ];
    };

    "/var/lib/NetworkManager" = {
      device = "/persist/var/lib/NetworkManager";
      options = [ "bind" "noauto" "x-systemd.automount" ];
    };

    "/var/lib/cups" = {
      device = "/persist/var/lib/cups";
      options = [ "bind" "noauto" "x-systemd.automount" ];
    };

    "/var/lib/systemd" = {
      device = "/persist/var/lib/systemd";
      options = [ "bind" "noauto" "x-systemd.automount" ];
    };

    "/var/lib/prometheus2" = {
      device = "/persist/var/lib/prometheus2";
      options = [ "bind" "noauto" "x-systemd.automount" ];
    };

    "/var/lib/upower" = {
      device = "/persist/var/lib/upower";
      options = [ "bind" "noauto" "x-systemd.automount" ];
    };

    "/var/lib/nixos" = {
      device = "/persist/var/lib/nixos";
      noCheck = true;
      options = [ "bind" ];
    };
  };
}
