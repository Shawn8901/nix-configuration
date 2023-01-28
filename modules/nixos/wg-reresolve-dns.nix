{ config, lib, pkgs, ... }:
let
  cfg = config.services.wireguard.reresolve-dns;
in
{
  options = {
    services.wireguard.reresolve-dns = {
      enable = lib.mkEnableOption "Set up service to use reresolve-dns from wireguard-tools to detect endpoint changes for wireguard server";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.wg-reresolve-dns;
        defaultText = lib.literalMD "pkgs.wg-reresolve-dns";
        description = lib.mdDoc "Which package to use for wg-reresolve-dns";
      };
      interval = lib.mkOption {
        default = "minutely";
        example = "minutely";
        description = lib.mdDoc "How often to run {command}`reresolve-dns`.";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    systemd.timers = lib.attrsets.mapAttrs'
      (name: _: lib.nameValuePair "wg-reresolve-dns-${name}"
        {
          wantedBy = [ "timers.target" ];
          after = [ "multi-user.target" ];
          timerConfig = {
            OnCalendar = cfg.interval;
            Persistent = "yes";
          };
        })
      config.networking.wg-quick.interfaces;

    systemd.services = lib.attrsets.mapAttrs'
      (name: _: lib.nameValuePair
        "wg-reresolve-dns-${name}"
        {
          description = "reresolve-dns for wg-quick-${name}";
          path = [ pkgs.wireguard-tools ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${cfg.package}/bin/reresolve-dns.sh ${name}";
          };
        })
      config.networking.wg-quick.interfaces;
  };
}
