{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption mkIf mdDoc types;
  cfg = config.hardware.asus-touchpad-numpad;
in {
  options = {
    hardware.asus-touchpad-numpad = {
      enable = mkEnableOption "Enables support for asus touchpad numpads";
      package = mkOption {
        type = types.package;
        description = mdDoc "Package to use as touchpad driver";
      };
      model = mkOption {
        type = types.str;
        description = "Model of the touchpad.";
      };
    };
  };
  config = mkIf cfg.enable {
    hardware.i2c.enable = true;

    systemd.services.asus-touchpad-numpad = {
      description =
        "Activate Numpad inside the touchpad with top right corner switch";
      script = ''
        ${cfg.package}/bin/asus_touchpad.py ${cfg.model}
      '';
      path = [ pkgs.i2c-tools ];
      after = [ "display-manager.service" ];
      requires = [ "display-manager.service" ];
      wantedBy = [ "graphical.target" ];
    };
  };
}
