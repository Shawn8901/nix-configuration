{
  self,
  inputs,
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
    };
    next = {
      profiles = ["server"];
      nixpkgs = inputs.nixpkgs-23_05;
    };

    pointalpha = {
      nixpkgs = inputs.nixpkgs-x86-64-v3;
      profiles = ["desktop" "optimized" "gaming"];
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
}
