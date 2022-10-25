{ ... }:
{ config, lib, pkgs, ... }:

let
  cfg = config.env.user-wayland;
in
{
  options = {
    env.user-wayland = {
      enable = lib.mkEnableOption "Use wayland on user applications";
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      MOZ_DISABLE_RDD_SANDBOX = 1;
    };

    programs.firefox = {
      package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
        forceWayland = true;
      };
    };
  };
}
