{ lib, osConfig, ... }:
let
  inherit (lib) versionOlder mkDefault;
in
lib.mkMerge [
  {
    home.stateVersion = "23.05";

    programs.zsh = {
      enable = true;
    };
    programs.dircolors = {
      enable = true;
      enableZshIntegration = true;
    };
    manual.manpages.enable = mkDefault false;
    programs.man.enable = mkDefault false;
  }
  (lib.optionalAttrs (!versionOlder osConfig.system.nixos.release "24.05") ({
    nix.gc = {
      automatic = true;
      options = "-d";
    };
  }))
]
