{ self, ... }@inputs:
name: nixpkgs:
nixpkgs.lib.nixosSystem (let
  configFolder = "${self}/machines/${name}";
  entryPoint = import "${configFolder}/configuration.nix" inputs;
  bootloader = "${configFolder}/bootloader.nix";
  hardware = import "${configFolder}/hardware.nix" inputs;
  home = "${configFolder}/home.nix";
  darlings = "${configFolder}/erase-darlings.nix";

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


  ] ++ builtins.attrValues self.nixosModules
    ++ nixpkgs.lib.optionals (builtins.pathExists home) [
      inputs.home-manager.nixosModule
      {
        home-manager = {
          extraSpecialArgs = { inherit inputs self; };
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules = [ (import ../modules/home-manager inputs) ];
          users.shawn = {
            home.stateVersion = "22.05";
            programs.zsh = { enable = true; };
            programs.git = {
              enable = true;
              userName = "Shawn8901";
              userEmail = "shawn8901@googlemail.com";
              ignores = [ "*.swp" ];
              extraConfig = { init = { defaultBranch = "main"; }; };
            };
          };
        };
      }
      (import home inputs)
    ] ++ nixpkgs.lib.optionals (builtins.pathExists darlings) [ darlings ];
})
