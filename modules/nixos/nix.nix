_:
{ pkgs, lib, ... }: {

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
      cores = lib.mkDefault 8;
      max-jobs = lib.mkDefault 8;
    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };
}
