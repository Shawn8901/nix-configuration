{ pkgs, lib, config, ... }:
{
  age.secrets.github_access_token = {
    file = ../../secrets/github_access_token.age;
    group = "nixbld";
    mode = "0440";
  };

  environment.systemPackages = [ pkgs.cachix ];
  nix = {
    package = pkgs.nix;
    settings = {
      auto-optimise-store = true;
      #allow-import-from-derivation = false;
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://shawn8901.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "shawn8901.cachix.org-1:7RAYBGET4e+szLrg86T9PP1vwDp+T99Fq0sTDt3B2DA="
      ];
      trusted-users = [ "root" "shawn" ];
      cores = lib.mkDefault 3;
      max-jobs = lib.mkDefault 2;
      experimental-features = "nix-command flakes";
    };
    extraOptions = ''
      !include ${config.age.secrets.github_access_token.path}
    '';
    nrBuildUsers = lib.mkForce 16;
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };
}
