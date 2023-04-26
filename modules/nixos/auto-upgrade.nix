{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.shawn8901.auto-upgrade;
in {
  options = {
    shawn8901.auto-upgrade = {
      enable = lib.mkEnableOption "Use auto-upgrade on that system";
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      dates = "07:00";
      flake = "github:shawn8901/nix-configuration";
      allowReboot = true;
      persistent = true;
    };
  };
}
