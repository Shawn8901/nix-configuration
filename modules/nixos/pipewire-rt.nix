{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.env.pipewire-rt;
in {
  options = {
    env.pipewire-rt = {
      enable = lib.mkEnableOption "service to save personal files to dropbox";
      rate = lib.mkOption {
        type = lib.types.int;
        default = 48000;
      };
      quantum = lib.mkOption {
        type = lib.types.int;
        default = 64;
      };
      minQuantum = lib.mkOption {
        type = lib.types.int;
        default = 32;
      };
      maxQuantum = lib.mkOption {
        type = lib.types.int;
        default = 8192;
      };
      rtLimitSoft = lib.mkOption {
        type = lib.types.int;
        default = 200000;
      };
      rtLimitHard = lib.mkOption {
        type = lib.types.int;
        default = 300000;
      };
    };
    config = lib.mkIf cfg.enable {
      security.rtkit.enable = true;

      services.pipewire = let
        qr = "${toString cfg.quantum}/${toString cfg.rate}";
      in {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        media-session.enable = false;
        wireplumber.enable = true;
        config.pipewire = {
          "context.properties" = {
            "link.max-buffers" = 16;
            "log.level" = 2;
            "default.clock.rate" = cfg.rate;
            "default.clock.quantum" = cfg.quantum;
            "default.clock.min-quantum" = cfg.minQuantum;
            "default.clock.max-quantum" = cfg.maxQuantum;
            "core.daemon" = true;
            "core.name" = "pipewire-0";
          };
          "context.modules" = [
            {
              name = "libpipewire-module-rtkit";
              args = {
                "nice.level" = -15;
                "rt.prio" = 88;
                "rt.time.soft" = cfg.rtLimitSoft;
                "rt.time.hard" = cfg.rtLimitHard;
              };
              flags = ["ifexists" "nofail"];
            }
            {name = "libpipewire-module-protocol-native";}
            {name = "libpipewire-module-profiler";}
            {name = "libpipewire-module-metadata";}
            {name = "libpipewire-module-spa-device-factory";}
            {name = "libpipewire-module-spa-node-factory";}
            {name = "libpipewire-module-client-node";}
            {name = "libpipewire-module-client-device";}
            {
              name = "libpipewire-module-portal";
              flags = ["ifexists" "nofail"];
            }
            {
              name = "libpipewire-module-access";
              args = {};
            }
            {name = "libpipewire-module-adapter";}
            {name = "libpipewire-module-link-factory";}
            {name = "libpipewire-module-session-manager";}
          ];
        };
        config.pipewire-pulse = {
          "context.properties" = {
            "log.level" = 2;
          };
          "context.modules" = [
            {
              name = "libpipewire-module-rtkit";
              args = {
                "nice.level" = -15;
                "rt.prio" = 88;
                "rt.time.soft" = cfg.rtLimitSoft;
                "rt.time.hard" = cfg.rtLimitHard;
              };
              flags = ["ifexists" "nofail"];
            }
            {name = "libpipewire-module-protocol-native";}
            {name = "libpipewire-module-client-node";}
            {name = "libpipewire-module-adapter";}
            {name = "libpipewire-module-metadata";}
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                "pulse.min.req" = qr;
                "pulse.default.req" = qr;
                "pulse.max.req" = qr;
                "pulse.min.quantum" = qr;
                "pulse.max.quantum" = qr;
                "server.address" = ["unix:native"];
              };
            }
          ];
          "stream.properties" = {
            "node.latency" = qr;
            "resample.quality" = 1;
          };
        };
      };
    };
  };
}
