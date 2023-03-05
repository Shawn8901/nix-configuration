{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.asus-touchpad-numpad;
in {
  options = {
    hardware.asus-touchpad-numpad = {
      enable = lib.mkEnableOption "Enables support for asus touchpad numpads";
      package = lib.mkOption {
        type = lib.types.package;
        description = lib.mdDoc "Package to use as touchpad driver";
      };
      model = lib.mkOption {
        type = lib.types.str;
        description = "Model of the touchpad.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    hardware.i2c.enable = true;

    systemd.services.asus-touchpad-numpad = {
      description = "Activate Numpad inside the touchpad with top right corner switch";
      script = ''
        ${cfg.package}/bin/asus_touchpad.py ${cfg.model}
      '';
      path = [pkgs.i2c-tools];
      after = ["display-manager.service"];
      wantedBy = ["graphical.target"];
    };
  };
}
