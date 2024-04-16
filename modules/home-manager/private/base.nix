{ lib, osConfig, ... }:
let
  inherit (lib) versionOlder;
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
    manual.manpages.enable = false;
  }
  (lib.optionalAttrs (!versionOlder osConfig.system.nixos.release "24.05") ({
    nix.gc = {
      automatic = true;
      options = "-d";
    };
  }))
]
