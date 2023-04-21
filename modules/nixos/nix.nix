{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  inherit (pkgs.hostPlatform) system;
  attic-client = inputs.attic.packages.${system}.attic-client;
  nixos-rebuild = pkgs.nixos-rebuild.override {nix = config.nix.package.out;};
in {
  sops.secrets = {
    nix-gh-token-ro = {
      sopsFile = ../../files/secrets-common.yaml;
      group = config.users.groups.nixbld.name;
      mode = "0440";
    };
    nix-netrc-ro = {
      sopsFile = ../../files/secrets-common.yaml;
      group = config.users.groups.nixbld.name;
      mode = "0440";
    };
  };

  environment.systemPackages = [attic-client nixos-rebuild];

  system.disableInstallerTools = true;
  system.build = {inherit nixos-rebuild;};

  nix = {
    package = pkgs.nix;
    settings = {
      auto-optimise-store = true;
      allow-import-from-derivation = false;
      substituters = ["https://cache.pointjig.de/nixos"];
      trusted-public-keys = ["nixos:vjrrtYYXDQx4qWPPQ0BeO2cr/O/VCkqOWgbFe2bPfi4="];
      trusted-users = ["root" "shawn"];
      cores = lib.mkDefault 6;
      max-jobs = lib.mkDefault 2;
      experimental-features = "nix-command flakes";
      netrc-file = lib.mkForce config.sops.secrets.nix-netrc-ro.path;
    };
    extraOptions = ''
      !include ${config.sops.secrets.nix-gh-token-ro.path}
      min-free = ${toString (1024 * 1024 * 1024)}
      max-free = ${toString (5 * 1024 * 1024 * 1024)}
    '';
    nrBuildUsers = lib.mkForce 16;
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
    gc = {
      automatic = true;
      dates = "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };
  };
}
