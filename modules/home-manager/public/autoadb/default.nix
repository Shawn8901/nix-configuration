{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.autoadb;
in
{
  options = {
    services.autoadb = {
      enable = mkEnableOption "autoadb service";
      package = mkOption {
        type = types.package;
        default = pkgs.autoadb;
        defaultText = literalExpression "pkgs.autoadb";
        description = "Which package to use for autoadb";
      };
      scrcpy.package = mkOption {
        type = types.package;
        default = pkgs.scrcpy;
        defaultText = literalExpression "pkgs.scrcpy";
        description = "Which package to use for scrcpy";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = cfg.package;

    systemd.user.services.autoadb = {
      Unit = {
        Description = "Start autoadb";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe cfg.package} ${lib.getExe cfg.scrcpy.package} -b 16M --render-driver opengles2 -s '{}'";
      };
    };
  };
}
