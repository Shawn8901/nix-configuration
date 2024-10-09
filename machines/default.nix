{
  inputs,
  lib,
  config,
  ...
}:
{
  config.fp-rndp-lib.nixosConfigurations = {
    watchtower = {
      hostPlatform.system = "aarch64-linux";
      nixpkgs = inputs.nixpkgs-stable;
      home-manager = {
        input = inputs.home-manager-stable;
        users = [ "shawn" ];
      };
      extraModules = [
        (inputs.attic + "/nixos/atticd.nix")
        ./watchtower/attic-server.nix
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
      inherit (inputs) nixpkgs;
      home-manager = {
        input = inputs.home-manager;
        users = [ "shawn" ];
      };
      extraModules = [
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    shelter = {
      nixpkgs = inputs.nixpkgs-stable;
      home-manager = {
        input = inputs.home-manager-stable;
        users = [ "shawn" ];
      };
    };
    tank = {
      inherit (inputs) nixpkgs;
      home-manager = {
        input = inputs.home-manager;
        users = [ "shawn" ];
      };
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
      inherit (inputs) nixpkgs;
    };
  };

  config.flake.hydraJobs = {
    nixos = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) config.flake.nixosConfigurations;
  };
}
