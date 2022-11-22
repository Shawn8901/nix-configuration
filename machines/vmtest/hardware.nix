{ config, pkgs, modulesPath, ... }:

{
  imports = [  (modulesPath + "/virtualisation/virtualbox-image.nix" ) ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
