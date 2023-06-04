{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.secrets = {
    influx-write-token = {
      sopsFile = ../../files/secrets-common.yaml;
    };
  };

  systemd.services.telegraf.path = lib.optionals (config.services.smartd.enable) [pkgs.smartmontools pkgs.nvme-cli];
  users.users.telegraf.extraGroups = lib.optionals (config.services.smartd.enable) ["disk"];

  services.telegraf = {
    enable = true;
    environmentFiles = [config.sops.secrets.influx-write-token.path];
    extraConfig = {
      outputs.influxdb_v2 = [
        {
          urls = ["https://influxdb.pointjig.de"];
          bucket = "flake";
          token = "$INFLUX_PASSWORD";
          organization = "Home";
        }
      ];
      inputs = lib.mkMerge [
        {
          cpu = {
            percpu = true;
            totalcpu = true;
            collect_cpu_time = false;
            report_active = false;
          };
          disk = {
            ignore_fs = ["tmpfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs"];
          };
          diskio = {};
          mem = {};
          net = {};
          processes = {};
          swap = {};
          system = {};
          systemd_units = {};
        }
        (lib.optionalAttrs (config.swapDevices != []) {swap = {};})
        (lib.optionalAttrs (builtins.elem "zfs" config.boot.supportedFilesystems) {
          zfs = {
            poolMetrics = true;
            datasetMetrics = true;
          };
        })
        (lib.optionalAttrs (config.services.smartd.enable) {
          smart = {};
        })

        # TODO: ZREPL, FRITZBOX, POSTGRES
      ];
    };
  };
}
