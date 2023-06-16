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
      hostPlatform.system = "aarch64-linux";
      nixpkgs = inputs.nixpkgs-stable;
      profiles = ["server" "managed-user"];
      homeManager.shawn.profiles = ["base"];
      hmInput = inputs.home-manager-stable;
    };
    next = {
      nixpkgs = inputs.nixpkgs-stable;
      profiles = ["server"];
    };

    pointalpha = {
      profiles = [
        "desktop"
        "optimized"
        "gaming"
      ];
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
      homeManager.shawn = {
        profiles = ["desktop" "development" "browser" "finance"];
      };
    };
    pointjig = {
      nixpkgs = inputs.nixpkgs-stable;
      profiles = ["server" "managed-user"];
      homeManager.shawn.profiles = ["base"];
      hmInput = inputs.home-manager-stable;
      extraModules = [
        inputs.simple-nixos-mailserver.nixosModules.default
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    shelter = {
      nixpkgs = inputs.nixpkgs-stable;
      profiles = ["server" "managed-user"];
      homeManager.shawn.profiles = ["base"];
      hmInput = inputs.home-manager-stable;
    };
    tank = {
      nixpkgs = inputs.nixpkgs-stable;
      profiles = ["server" "managed-user"];
      homeManager.shawn.profiles = ["base"];
      hmInput = inputs.home-manager-stable;
      extraModules = [
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    zenbook = {
      profiles = ["desktop" "gaming"];
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
      homeManager.shawn = {
        profiles = ["desktop" "development" "browser"];
      };
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
