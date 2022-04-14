{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.autoadb;
in
{

  options = {
    services.autoadb = { enable = mkEnableOption "autoadb service"; };
  };

  config = mkIf cfg.enable {
    systemd.user.services.autoadb = {
      Unit = { Description = "Start autoadb"; };
      Install = { WantedBy = [ "graphical-session.target" ]; };
      Service = {
        Slice = "session.slice";
        ExecStart = "${pkgs.autoadb}/bin/autoadb ${pkgs.scrcpy}/bin/scrcpy -b 16M --render-driver opengles2 -s '{}'";
        Environment = [ "DISPLAY=:1" "XAUTHORITY=/run/user/1000/gdm/Xauthority" ];
      };
    };
  };
}
