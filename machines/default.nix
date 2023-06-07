{
  self,
  inputs,
  lib,
  config,
  withSystem,
  ...
}: let
  inherit (config.shawn8901.system-generator) generateSystem;
  cfg = config.shawn8901.nixosConfigurations;
in {
  config.shawn8901.nixosConfigurations = {
    cache = {
      profiles = ["server" "managed-user"];
      hostPlatform.system = "aarch64-linux";
      nixpkgs = inputs.nixpkgs-23_05;
    };
    next = {
      profiles = ["server"];
      nixpkgs = inputs.nixpkgs-23_05;
    };

    pointalpha = {
      profiles = [
        "desktop"
        # "optimized"
        "gaming"
      ];
      homeManager.shawn = {
        profiles = ["base" "development" "browser" "finance"];
      };
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
      ];
    };
    pointjig = {
      profiles = ["server" "managed-user"];
      nixpkgs = inputs.nixpkgs-23_05;
      extraModules = [
        inputs.simple-nixos-mailserver.nixosModules.default
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    shelter = {
      profiles = ["server" "managed-user"];
      nixpkgs = inputs.nixpkgs-23_05;
    };
    tank = {
      profiles = ["server" "managed-user"];
      nixpkgs = inputs.nixpkgs-23_05;
      extraModules = [
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    zenbook = {
      profiles = ["desktop" "gaming"];
      homeManager.shawn = {
        profiles = ["base" "development" "browser"];
      };
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
    };
  };

  config.flake.nixosConfigurations = generateSystem cfg;

  config.flake.hydraJobs = {
    nixos = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) config.flake.nixosConfigurations;
    "merge-pr" = withSystem "x86_64-linux" (
      {pkgs, ...}:
        pkgs.releaseTools.aggregate {
          name = "merge-pr";
          meta = {schedulingPriority = 50;};
          constituents = map (n: "nixos." + n) (builtins.attrNames config.flake.hydraJobs.nixos);
        }
    );
  };
}
