{ self, config, lib, moduleWithSystem, ... }:
let
  inherit (builtins) readDir attrNames;
  inherit (lib) filterAttrs genAttrs;
  inherit (config.shawn8901.module-generator) generateModules;

  modules = generateModules "${self}/modules/home-manager";
in {
  # expose as modules after merge of https://github.com/NixOS/nix/pull/8332
  flake.flakeModules.homeManager = modules;
}
