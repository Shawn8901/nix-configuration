{ self, ... }@inputs:
name: nixpkgs:
nixpkgs.lib.nixosSystem (let
  configFolder = "${self}/machines/${name}";
  entryPoint = import "${configFolder}/configuration.nix" inputs;
  bootloader = "${configFolder}/bootloader.nix";
  hardware = "${configFolder}/hardware.nix";
  home = "${configFolder}/home.nix";
in {
  system = "x86_64-linux";

  modules = [
    {
      boot.cleanTmpDir = true;
      networking.hostName = name;
      networking.hostId =
        builtins.substring 0 8 (builtins.hashString "md5" "${name}");
      system.configurationRevision = self.rev or "dirty";
      documentation.nixos.enable = false;
      documentation.man = {
        enable = true;
        generateCaches = true;
      };
      system.stateVersion = "22.05";
    }
    entryPoint
    bootloader
    hardware

    inputs.agenix.nixosModule
    inputs.home-manager.nixosModule

  ] ++ builtins.attrValues self.nixosModules
    ++ nixpkgs.lib.optionals (builtins.pathExists home) [

      { home-manager = { extraSpecialArgs = { inherit inputs self; }; }; }

      (import home inputs)
    ];
})
