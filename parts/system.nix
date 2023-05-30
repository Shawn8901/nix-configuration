{
  self,
  config,
  inputs,
  lib,
  withSystem,
  ...
}: let
  inherit (lib) mkOption types concatMap;
  inherit (builtins) readDir mapAttrs pathExists attrValues;
  inherit (config.shawn8901.profile-generator) generateModulesFromNixOSProfiles generateModulesFromHmProfiles;

  baseConfigType = {
    stateVersion = mkOption {
      type = types.str;
      default = "22.05";
    };
    profiles = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    extraModules = mkOption {
      type = types.listOf types.unspecified;
      default = [];
    };
  };
in {
  options = {
    shawn8901 = {
      result = mkOption {
        type = types.unspecified;
      };
      system-generator = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
      };
      nixosConfigurations = mkOption {
        default = {};
        type = types.attrsOf (types.submodule (
          {
            name,
            config,
            ...
          }: {
            options =
              {
                nixpkgs = mkOption {
                  type = types.unspecified;
                  default = inputs.nixpkgs;
                };
                hostPlatform.system = mkOption {
                  type = types.enum ["x86_64-linux" "aarch64-linux"];
                  default = "x86_64-linux";
                };
                unfreeSoftware = mkOption {
                  type = types.listOf types.str;
                  default = [];
                };
                homeManager = mkOption {
                  default = {};
                  type = types.attrsOf (types.submodule (
                    {
                      name,
                      config,
                      ...
                    }: {
                      options = baseConfigType;
                    }
                  ));
                };
              }
              // baseConfigType;
          }
        ));
      };
    };
  };
  config.shawn8901.system-generator.generateSystem = mapAttrs (
    name: conf:
      withSystem conf.hostPlatform.system ({
        system,
        inputs',
        self',
        ...
      }: let
        inherit (conf.nixpkgs) lib;

        configDir = "${self}/machines/${name}";
        darlings = "${configDir}/save-darlings.nix";
        extraArgs = {
          inherit self self' inputs inputs';
          fConfig = config;
        };
      in
        lib.nixosSystem {
          modules =
            [
              {
                _module.args = extraArgs;
                nixpkgs = {inherit (conf) hostPlatform;};
                networking.hostName = name;
                networking.hostId = builtins.substring 0 8 (builtins.hashString "md5" "${name}");
                nix.registry = {
                  nixpkgs.flake = conf.nixpkgs;
                  nixos-config.flake = inputs.self;
                };
                nix.nixPath = ["nixpkgs=${conf.nixpkgs}"];
                system.configurationRevision = self.rev or "dirty";
                system.stateVersion = conf.stateVersion;
                sops.defaultSopsFile = "${configDir}/secrets.yaml";
                nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) conf.unfreeSoftware;
              }

              "${configDir}/configuration.nix"
              "${configDir}/hardware.nix"

              inputs.sops-nix.nixosModules.sops
              inputs.attic.nixosModules.atticd
            ]
            ++ (attrValues self.flakeModules.nixos)
            ++ (attrValues self.flakeModules.private.nixos)
            ++ (generateModulesFromNixOSProfiles conf.profiles)
            ++ conf.extraModules
            ++ lib.optionals (builtins.pathExists darlings) [darlings]
            ++ lib.optionals (conf.homeManager != {}) [
              inputs.home-manager.nixosModule
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = extraArgs;
                  sharedModules =
                    [inputs.sops-nix.homeManagerModules.sops]
                    ++ (attrValues self.flakeModules.homeManager);
                  users =
                    mapAttrs (
                      name: hmConf: {
                        imports = generateModulesFromHmProfiles hmConf.profiles;
                        home.stateVersion = hmConf.stateVersion;
                        nix.registry.nixpkgs.flake = conf.nixpkgs;
                      }
                    )
                    conf.homeManager;
                };
              }
            ];
        })
  );
}
