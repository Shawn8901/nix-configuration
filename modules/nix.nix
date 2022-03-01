{ config, pkgs, ... }:

{
  nix = {
    package = pkgs.nixUnstable;
    settings.auto-optimise-store = true;
    generateNixPathFromInputs = true;
    generateRegistryFromInputs = true;
    linkInputs = true;
    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
