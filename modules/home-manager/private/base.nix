{ lib, osConfig, ... }:
let
  inherit (lib) versionOlder mkDefault;
in
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
  nix.gc = {
    automatic = true;
    options = "-d";
  };
}
