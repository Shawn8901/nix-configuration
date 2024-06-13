{
  self,
  self',
  inputs,
  lib,
  config,
  withSystem,
  ...
}:
let
  inherit (config.shawn8901.system-generator) generateSystem;
  cfg = config.shawn8901.nixosConfigurations;
in
{
  config.fp-rndp-lib.nixosConfigurations = {
    watchtower = {
      hostPlatform.system = "aarch64-linux";
      nixpkgs = inputs.nixpkgs-stable;
      hmInput = inputs.home-manager-stable;
      home-manager.shawn = { };
      extraModules = [
        (inputs.attic + "/nixos/atticd.nix")
        ../modules/nixos/attic-server
      ];
    };
    next = {
      nixpkgs = inputs.nixpkgs-stable;
    };
    pointalpha = {
      inherit (inputs) nixpkgs;
      hmInput = inputs.home-manager;
      unfreeSoftware = [
        "steam"
        "steam-run"
        "steam-original"
        "vscode"
        "vscode-extension-MS-python-vscode-pylance"
        "deezer"
        "discord"
        "teamspeak-client"
        "tampermonkey"
        "betterttv"
        "teamviewer"
        "keymapp"
        "epsonscan2"
      ];
      home-manager.shawn = { };
    };
    pointjig = {
      inherit (inputs) nixpkgs;
      hmInput = inputs.home-manager;
      home-manager.shawn = { };
      extraModules = [
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    shelter = {
      nixpkgs = inputs.nixpkgs-stable;
      hmInput = inputs.home-manager-stable;
      home-manager.shawn = { };
    };
    tank = {
      inherit (inputs) nixpkgs;
      hmInput = inputs.home-manager;
      home-manager.shawn = { };
      extraModules = [
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    zenbook = {
      inherit (inputs) nixpkgs;
      hmInput = inputs.home-manager;
      unfreeSoftware = [
        "steam"
        "steam-run"
        "steam-original"
        "vscode"
        "vscode-extension-MS-python-vscode-pylance"
        "deezer"
        "discord"
        "teamspeak-client"
        "tampermonkey"
        "betterttv"
      ];
      home-manager.shawn = { };
    };
    trivia-gs = {
      inherit (inputs) nixpkgs;
    };
  };

  config.flake.hydraJobs = {
    nixos = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) config.flake.nixosConfigurations;
  };
}
