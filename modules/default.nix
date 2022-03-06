{ config, pkgs, ... }:

{
  imports = [
    ./nix.nix
    ./build-tools.nix
    ./home-manager.nix
  ];
}
