{ self, inputs, lib, config, withSystem, ... }:
let
  inherit (config.shawn8901.system-generator) generateSystem;
  cfg = config.shawn8901.nixosConfigurations;
in {
  config.shawn8901.nixosConfigurations = {
    cache = {
      hostPlatform.system = "aarch64-linux";
      nixpkgs = inputs.nixpkgs-stable;
      hmInput = inputs.home-manager-stable;
      profiles = [ "server" "managed-user" ];
      homeManager.shawn.profiles = [ "base" ];
      disabledModules = [ "services/monitoring/vmagent.nix" ];
      extraModules = [
        (inputs.nixpkgs.outPath
          + "/nixos/modules/services/monitoring/vmagent.nix")
      ];
    };
    next = {
      nixpkgs = inputs.nixpkgs-stable;
      profiles = [ "server" ];
      disabledModules = [ "services/monitoring/vmagent.nix" ];
      extraModules = [
        (inputs.nixpkgs.outPath
          + "/nixos/modules/services/monitoring/vmagent.nix")
      ];
    };
    pointalpha = {
      nixpkgs = inputs.nixpkgs;
      hmInput = inputs.home-manager;
      profiles = [ "desktop" "gaming" ];
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
        profiles = [ "desktop" "development" "browser" "finance" ];
      };
    };
    pointjig = {
      nixpkgs = inputs.nixpkgs-stable;
      hmInput = inputs.home-manager-stable;
      profiles = [ "server" "managed-user" ];
      homeManager.shawn.profiles = [ "base" ];
      extraModules = [
        inputs.simple-nixos-mailserver.nixosModules.default
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
        (inputs.nixpkgs.outPath
          + "/nixos/modules/services/monitoring/vmagent.nix")
      ];
      disabledModules = [ "services/monitoring/vmagent.nix" ];
    };
    shelter = {
      nixpkgs = inputs.nixpkgs-stable;
      hmInput = inputs.home-manager-stable;
      profiles = [ "server" "managed-user" ];
      homeManager.shawn.profiles = [ "base" ];
      disabledModules = [ "services/monitoring/vmagent.nix" ];
      extraModules = [
        (inputs.nixpkgs.outPath
          + "/nixos/modules/services/monitoring/vmagent.nix")
      ];
    };
    tank = {
      nixpkgs = inputs.nixpkgs;
      hmInput = inputs.home-manager;
      profiles = [ "server" "managed-user" ];
      homeManager.shawn.profiles = [ "base" ];
      extraModules = [
        inputs.mimir.nixosModules.default
        inputs.stfc-bot.nixosModules.default
      ];
    };
    zenbook = {
      nixpkgs = inputs.nixpkgs;
      hmInput = inputs.home-manager;
      profiles = [ "desktop" "gaming" ];
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
      homeManager.shawn = { profiles = [ "desktop" "development" "browser" ]; };
    };
  };

  config.flake.nixosConfigurations = generateSystem cfg;

  config.flake.hydraJobs = {
    nixos = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel)
      config.flake.nixosConfigurations;
    "merge-pr" = withSystem "x86_64-linux" ({ pkgs, ... }:
      pkgs.releaseTools.aggregate {
        name = "merge-pr";
        meta = { schedulingPriority = 10; };
        constituents = map (n: "nixos." + n)
          (builtins.attrNames config.flake.hydraJobs.nixos);
      });
  };
}
