{ config, pkgs, ... }:

{
  imports = [
    ./locale.nix
    ./nix.nix
    ./build-tools.nix
    ./home-manager.nix
    ./user-config.nix

    ./services/mimir.nix
  ];
}
