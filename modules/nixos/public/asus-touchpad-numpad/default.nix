{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    types
    ;

  cfg = config.hardware.asus-numberpad-driver;
in
{
  options = {
    hardware.asus-numberpad-driver = {
      enable = mkEnableOption "Enables support for asus touchpad numpads";
      package = mkPackageOption pkgs "asus-numberpad-driver";
      model = mkOption {
        type = types.str;
        description = "Model of the touchpad.";
      };
    };
  };
  config = mkIf cfg.enable {
    hardware.i2c.enable = true;

    systemd.services.asus-numberpad-driver = {
      description = "Activate Numpad inside the touchpad with top right corner switch";
      script = "${lib.getExe cfg.package} ${cfg.model}";
      path = [ pkgs.i2c-tools ];

      after = [ "display-manager.service" ];
      requires = [ "display-manager.service" ];
      wantedBy = [ "graphical.target" ];
    };
  };
}
