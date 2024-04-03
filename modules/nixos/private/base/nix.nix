{
  self,
  pkgs,
  lib,
  config,
  inputs',
  ...
}:
let
  inherit (pkgs.hostPlatform) system;
  inherit (lib)
    genAttrs
    mkIf
    mkDefault
    mkForce
    versionOlder
    ;
in
{
  sops.secrets = {
    nix-gh-token-ro = {
      sopsFile = ../../../../files/secrets-common.yaml;
      group = config.users.groups.nixbld.name;
      mode = "0444";
    };
    nix-netrc-ro = {
      sopsFile = ../../../../files/secrets-common.yaml;
      group = config.users.groups.nixbld.name;
      mode = "0444";
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      auto-optimise-store = true;
      allow-import-from-derivation = false;
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.pointjig.de/nixos"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixos:5axzveeiERb8xAeioBUHNHq4SVLvwDcJkLMFsWq0l1E="
      ];
      cores = mkDefault 6;
      max-jobs = mkDefault 2;
      experimental-features = "nix-command flakes";
      netrc-file = mkForce config.sops.secrets.nix-netrc-ro.path;
    };
    extraOptions = ''
      !include ${config.sops.secrets.nix-gh-token-ro.path}
      min-free = ${toString (1024 * 1024 * 1024)}
      max-free = ${toString (5 * 1024 * 1024 * 1024)}
    '';
    nrBuildUsers = mkForce 16;
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
    gc = {
      automatic = true;
      dates = "weekly";
      options = mkDefault "--delete-older-than 7d";
    };
  };
}
