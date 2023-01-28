{ pkgs, lib, config, inputs, ... }:
let
  system = pkgs.hostPlatform.system;
in
{
  age.secrets = {
    nix-gh-token = {
      file = ../../secrets/nix-gh-token.age;
      group = "nixbld";
      mode = "0440";
    };
    nix-netrc = {
      file = ../../secrets/nix-netrc-ro.age;
      group = "nixbld";
      mode = "0440";
    };
  };

  environment.systemPackages = [ (inputs.attic.packages.${system}.attic-client.overrideAttrs (attr: { stdenv = pkgs.clangStdenv; })) ];
  nix = {
    package = pkgs.nix;
    settings = {
      auto-optimise-store = true;
      #allow-import-from-derivation = false;
      substituters = [ "https://cache.pointjig.de/nixos" ];
      trusted-public-keys = [ "nixos:vjrrtYYXDQx4qWPPQ0BeO2cr/O/VCkqOWgbFe2bPfi4=" ];
      trusted-users = [ "root" "shawn" ];
      cores = lib.mkDefault 4;
      max-jobs = lib.mkDefault 2;
      experimental-features = "nix-command flakes";
      netrc-file = lib.mkForce config.age.secrets.nix-netrc.path;
    };
    extraOptions = ''
      !include ${config.age.secrets.nix-gh-token.path}
    '';
    nrBuildUsers = lib.mkForce 16;
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
    gc = {
      automatic = true;
      dates = "daily";
      options = lib.mkDefault "--delete-older-than 7d";
    };
  };
}
