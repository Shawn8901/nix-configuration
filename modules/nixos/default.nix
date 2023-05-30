{
  self,
  config,
  ...
}: let
  inherit (config.shawn8901.module-generator) generateModules;

  modules = generateModules "${self}/modules/nixos";
  privateModules = generateModules "${self}/modules/nixos/_private";
in {
  flake.nixosModules = modules;
  # expose as modules after merge of https://github.com/NixOS/nix/pull/8332
  flake.flakeModules.nixos = modules;
  flake.flakeModules.private.nixos = privateModules;
}
