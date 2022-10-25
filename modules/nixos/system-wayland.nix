{ ... }:
{ config, lib, pkgs, ... }:

let
  cfg = config.env.system-wayland;
in
{
  options = {
    env.system-wayland = {
      enable = lib.mkEnableOption "Use wayland on system";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.xwayland.enable = true;

    services.xserver = {
      enable = true;
      layout = "de";
      videoDrivers = [ "amdgpu" ];
      displayManager.sddm = {

        #package = fPkgs.sddm-git;
        settings = {
          General = {
            #DisplayServer = "wayland";
            GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
          };
          Wayland = {
            CompositorCommand = "kwin_wayland --no-lockscreen --inputmethod qt5-virtualkeyboard";
          };
        };
      };
      displayManager.defaultSession = "plasmawayland";
    };
    environment = {
      variables.NIXOS_OZONE_WL = "1";
      variables.SDL_VIDEODRIVER = "wayland";
      variables.QT_QPA_PLATFORM = "wayland-egl";
      variables.QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      variables._JAVA_AWT_WM_NONREPARENTING = "1";
    };
  };
}
