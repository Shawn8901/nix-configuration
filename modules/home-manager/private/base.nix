{ lib, osConfig, ... }:
let
  inherit (lib) versionOlder mkDefault;
in
lib.mkMerge [
  {
    home.stateVersion = "23.05";

    programs = {
      zsh.enable = true;
      dircolors = {
        enable = true;
        enableZshIntegration = true;
      };
      man.enable = mkDefault false;
    };
    manual.manpages.enable = mkDefault false;
  }
  (lib.optionalAttrs (!versionOlder osConfig.system.nixos.release "24.05") {
    nix.gc = {
      automatic = true;
      options = "-d";
    };
  })
]
