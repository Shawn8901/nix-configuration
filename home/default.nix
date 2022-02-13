{ config, pkgs, inputs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    sharedModules = [ ];
    users = {
      shawn = {
        home.stateVersion = "22.05";
        imports = [
          ./git.nix
        ];
      };
    };
  };
}
