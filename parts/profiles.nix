{
  self,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types filterAttrs genAttrs concatMap unique;
  inherit (builtins) hasAttr;

  inherit (config.shawn8901.module-generator) generateModule;

  profileType = types.submodule (
    {
      name,
      config,
      ...
    }: {
      options = {
        modules = mkOption {
          type = types.listOf types.unspecified;
          default = [];
        };
        profiles = mkOption {
          type = types.listOf types.unspecified;
          default = [];
        };
      };
    }
  );
in {
  options = {
    shawn8901 = {
      profile-generator = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
      };
      profiles = {
        nixos = mkOption {
          type = types.attrsOf profileType;
        };
        home-manager = mkOption {
          type = types.attrsOf profileType;
        };
      };
    };
  };
  config.shawn8901.profile-generator = rec {
    expandProfileToModuleInternal = type: profile:
      if ((profile.profiles or []) != [])
      then (concatMap (profile: expandProfileToModuleInternal type config.shawn8901.profiles.${type}.${profile}) profile.profiles) ++ profile.modules
      else profile.modules;
    profileToModules = type: profile: unique (expandProfileToModuleInternal type profile);
    getUniqueModules = type: profiles: unique (concatMap (profile: profileToModules type config.shawn8901.profiles.${type}.${profile}) profiles);

    generateModulesFromProfile = type: profilFile: generateModule "${self}/profiles/${type}/${profilFile}";
    generateModulesFromNixOSProfiles = profiles: map (profile: generateModulesFromProfile "nixos" profile) (getUniqueModules "nixos" profiles);
    generateModulesFromHmProfiles = profiles: map (profile: generateModulesFromProfile "home-manager" profile) (getUniqueModules "home-manager" profiles);
  };
}
