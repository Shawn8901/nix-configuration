_:
{ config, lib, pkgs, ... }:

with lib;
let cfg = config.services.autoadb;
in
{

  options = {
    services.autoadb = { enable = mkEnableOption "autoadb service"; };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ autoadb ];

    systemd.user.services.autoadb = {
      Unit = { Description = "Start autoadb"; };
      Install = { WantedBy = [ "default.target" ]; };
      Service = {
        ExecStart = "${pkgs.autoadb}/bin/autoadb ${pkgs.scrcpy}/bin/scrcpy -b 16M --render-driver opengles2 -s '{}'";
      };
    };
  };
}
