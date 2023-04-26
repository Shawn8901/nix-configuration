{
  self,
  home-manager,
  sops-nix,
  attic,
  simple-nixos-mailserver,
  ...
} @ inputs: name: nixpkgs:
nixpkgs.lib.nixosSystem
(
  let
    configFolder = "${self}/machines/${name}";
    entryPoint = import "${configFolder}/configuration.nix";
    bootloader = "${configFolder}/bootloader.nix";
    hardware = import "${configFolder}/hardware.nix";
    home = "${configFolder}/home.nix";
    darlings = "${configFolder}/save-darlings.nix";

    extraAgs = {inherit self inputs;};
  in {
    specialArgs = extraAgs;
    modules =
      [
        {
          boot.cleanTmpDir = true;
          networking.hostName = name;
          networking.hostId = builtins.substring 0 8 (builtins.hashString "md5" "${name}");
          system.configurationRevision = self.rev or "dirty";
          documentation.doc.enable = false;
          documentation.man = {
            enable = true;
            generateCaches = true;
          };
          nix.registry = {
            nixpkgs.flake = nixpkgs;
            system.flake = inputs.self;
          };
          nix.nixPath = ["nixpkgs=${nixpkgs}"];
          system.stateVersion = "22.05";
          sops.defaultSopsFile = "${configFolder}/secrets.yaml";
        }
        entryPoint
        bootloader
        hardware
        sops-nix.nixosModules.sops
        attic.nixosModules.atticd
      ]
      ++ builtins.attrValues self.nixosModules
      ++ builtins.attrValues (import ../modules/nixos)
      ++ nixpkgs.lib.optionals (builtins.pathExists home)
      [
        home-manager.nixosModule
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = extraAgs;
          };
          home-manager.users.root = {
            home.stateVersion = "22.05";
          };
        }
        {
          home-manager = {
            sharedModules = [
              {
                imports =
                  builtins.attrValues self.flakeModules.homeManager
                  ++ builtins.attrValues (import ../modules/home-manager);
              }
              sops-nix.homeManagerModules.sops
            ];
            users.shawn = {
              home.stateVersion = "22.05";
              nix.registry.nixpkgs.flake = nixpkgs;
              programs.zsh = {enable = true;};
              programs.git = {
                enable = true;
                userName = "Shawn8901";
                userEmail = "shawn8901@googlemail.com";
                ignores = ["*.swp"];
                extraConfig = {init = {defaultBranch = "main";};};
              };
            };
          };
        }
        home
      ]
      ++ nixpkgs.lib.optionals (builtins.pathExists darlings) [darlings];
  }
)
