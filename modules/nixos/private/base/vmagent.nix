{ self, config, lib, pkgs, flakeConfig, ... }: {
  sops.secrets = {
    vmagent = {
      sopsFile = ../../../../files/secrets-common.yaml;
      owner = config.services.vmagent.user;
      group = config.services.vmagent.group;
    };
  };

  services = {
    vmagent = {
      enable = true;
      remoteWriteUrl = "https://vm.pointjig.de/api/v1/write";
      extraArgs = [
        "-remoteWrite.basicAuth.username=vm"
        "-remoteWrite.basicAuth.passwordFile=${config.sops.secrets.vmagent.path}"
        "-remoteWrite.label=instance=${config.networking.hostName}"
      ];
      prometheusConfig = {
        global = {
          scrape_interval = "1m";
          scrape_timeout = "30s";
        };
        scrape_configs = [{
          job_name = "node";
          static_configs = [{
            targets = [
              "localhost:${
                toString config.services.prometheus.exporters.node.port
              }"
            ];
          }];
        }] ++ lib.optionals (config.services.prometheus.exporters.zfs.enable) [{
          job_name = "zfs";
          static_configs = [{
            targets = [
              "localhost:${
                toString config.services.prometheus.exporters.zfs.port
              }"
            ];
          }];
        }] ++ lib.optionals
          (config.services.prometheus.exporters.smartctl.enable) [{
            job_name = "smartctl";
            static_configs = [{
              targets = [
                "localhost:${
                  toString config.services.prometheus.exporters.smartctl.port
                }"
              ];
            }];
          }] ++ lib.optionals (config.services.zrepl.enable) [{
            job_name = "zrepl";
            static_configs = [{
              targets = [
                "localhost:${
                  toString (flakeConfig.shawn8901.zrepl.monitoringPorts
                    config.services.zrepl)
                }"
              ];
            }];
          }];
      };
    };
    prometheus.exporters = lib.mkMerge [
      {
        node = {
          enable = true;
          listenAddress = "localhost";
          port = 9101;
          enabledCollectors =
            [ "systemd" "processes" "interrupts" "cgroups" "hwmon" ];
        };
      }
      (lib.optionalAttrs
        (builtins.elem "zfs" config.boot.supportedFilesystems) {
          zfs = {
            enable = true;
            listenAddress = "localhost";
          };
        })
      (lib.optionalAttrs (config.services.smartd.enable) {
        smartctl = {
          enable = true;
          listenAddress = "localhost";
          devices = [ "/dev/sda" ];
          maxInterval = "5m";
        };
      })
    ];
  };
}
