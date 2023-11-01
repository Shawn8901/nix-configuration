{ self, lib, moduleWithSystem, ... }:
let
  inherit (lib)
    mkOption types filterAttrs genAttrs mapAttrs' nameValuePair removeSuffix
    hasSuffix;
  inherit (builtins) readDir attrNames;

  # Modules with <name>.nix are seen as private and get a username prefix
  scopeModules =
    mapAttrs' (name: value: nameValuePair (removeSuffix ".nix" name) value);
in {
  options = {
    shawn8901.module-generator = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };

  config.shawn8901.module-generator = rec {
    getModulesFiles = dir:
      builtins.attrNames
      (lib.filterAttrs (name: type: name != "default.nix" && name != "_private")
        (builtins.readDir dir));

    generateModule = modulePath:
      moduleWithSystem
      (perSystem@{ config }: { ... }@inputs: { imports = [ modulePath ]; });

    generateModules = baseDir:
      (scopeModules (genAttrs (getModulesFiles baseDir)
        (name: generateModule "${baseDir}/${name}")));
  };
}
