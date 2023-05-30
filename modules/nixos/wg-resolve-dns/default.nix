{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf mdDoc literalMD types attrsets;

  cfg = config.services.wireguard.reresolve-dns;
in {
  options = {
    services.wireguard.reresolve-dns = {
      enable = mkEnableOption "Set up service to use reresolve-dns from wireguard-tools to detect endpoint changes for wireguard server";
      package = mkOption {
        type = types.package;
        default = pkgs.wg-reresolve-dns;
        defaultText = literalMD "pkgs.wg-reresolve-dns";
        description = mdDoc "Which package to use for wg-reresolve-dns";
      };
      interval = mkOption {
        default = "minutely";
        example = "minutely";
        description = mdDoc "How often to run {command}`reresolve-dns`.";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.timers = attrsets.mapAttrs' (name: _:
      lib.nameValuePair "wg-reresolve-dns-${name}" {
        wantedBy = ["timers.target"];
        after = ["multi-user.target"];
        timerConfig = {
          OnCalendar = cfg.interval;
          Persistent = "yes";
        };
      })
    config.networking.wg-quick.interfaces;

    systemd.services = attrsets.mapAttrs' (name: _:
      lib.nameValuePair "wg-reresolve-dns-${name}" {
        description = "reresolve-dns for wg-quick-${name}";
        path = [pkgs.wireguard-tools];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${cfg.package}/bin/reresolve-dns.sh ${name}";
        };
      })
    config.networking.wg-quick.interfaces;
  };
}
