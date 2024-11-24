{
  inputs,
  lib,
  config,
  ...
}:
{
  config.fp-lib.nixosConfigurations = {
    watchtower = {
      hostPlatform.system = "aarch64-linux";
      nixpkgs = inputs.nixpkgs-stable;
      extraModules = [
        ./watchtower/attic-server.nix
        ./watchtower/victoriametrics.nix
      ];
    };
    next = {
      nixpkgs = inputs.nixpkgs-stable;
    };
    pointalpha = {
      inherit (inputs) nixpkgs;
      home-manager = {
        input = inputs.home-manager;
        users = [ "shawn" ];
      };
    };
    pointjig = {
      nixpkgs = inputs.nixpkgs-stable;
      extraModules = [
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    shelter = {
      nixpkgs = inputs.nixpkgs-stable;
    };
    tank = {
      inherit (inputs) nixpkgs;
      extraModules = [
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    zenbook = {
      inherit (inputs) nixpkgs;
      home-manager = {
        input = inputs.home-manager;
        users = [ "shawn" ];
      };
    };
    trivia-gs = {
      nixpkgs = inputs.nixpkgs-stable;
    };
  };

  config.flake.hydraJobs = {
    nixos = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) config.flake.nixosConfigurations;
  };
}
