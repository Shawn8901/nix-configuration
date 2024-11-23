{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkDefault
    mkForce
    versionOlder
    ;
in
{
  sops.secrets = {
    nix-gh-token-ro = {
      sopsFile = ../../../../files/secrets-base.yaml;
      group = config.users.groups.nixbld.name;
      mode = "0444";
    };
    nix-netrc-ro = {
      sopsFile = ../../../../files/secrets-base.yaml;
      group = config.users.groups.nixbld.name;
      mode = "0444";
    };
  };

  nix = {
    channel.enable = false;
    package = pkgs.nix;
    settings = {
      auto-optimise-store = true;
      allow-import-from-derivation = false;
      substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixos:5axzveeiERb8xAeioBUHNHq4SVLvwDcJkLMFsWq0l1E="
      ];
      cores = mkDefault 6;
      max-jobs = mkDefault 2;
      experimental-features = "nix-command flakes";
    };
    extraOptions = ''
      !include ${config.sops.secrets.nix-gh-token-ro.path}
      min-free = ${toString (1024 * 1024 * 1024)}
      max-free = ${toString (5 * 1024 * 1024 * 1024)}
    '';
    nrBuildUsers = mkForce 16;
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
  };

  programs.nh = {
    enable = true;
    flake = mkIf (!versionOlder config.system.nixos.release "25.05") (
      lib.mkDefault "github:shawn8901/nix-configuration"
    );
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 3d";
    };
  };
}
