{ self, home-manager, ... }@inputs:
name: nixpkgs:

nixpkgs.lib.nixosSystem
  (
    let
      configFolder = "${self}/machines/${name}";
      entryPoint = import "${configFolder}/configuration.nix";
      bootloader = "${configFolder}/bootloader.nix";
      hardware = import "${configFolder}/hardware.nix";
      home = "${configFolder}/home.nix";
      darlings = "${configFolder}/save-darlings.nix";

      extraAgs = { inherit self inputs; };
    in
    {
      specialArgs = extraAgs;
      modules = [
        {
          boot.cleanTmpDir = true;
          networking.hostName = name;
          networking.hostId = builtins.substring 0 8 (builtins.hashString "md5" "${name}");
          system.configurationRevision = self.rev or "dirty";
          documentation.man = {
            enable = true;
            generateCaches = true;
          };
          nix.registry = {
            nixpkgs.flake = nixpkgs;
            system.flake = inputs.self;
          };
          nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
          system.stateVersion = "22.05";
        }
        entryPoint
        bootloader
        hardware

        inputs.agenix.nixosModule
        self.nixosModules
      ]
      ++ nixpkgs.lib.optionals (builtins.pathExists home)
        [
          home-manager.nixosModule
          {
            home-manager =
              {
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
              sharedModules = [ ../modules/home-manager ];
              users.shawn = {
                home.stateVersion = "22.05";
                nix.registry.nixpkgs.flake = nixpkgs;
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
          home
        ]
      ++ nixpkgs.lib.optionals (builtins.pathExists darlings) [ darlings ];
    }
  )
