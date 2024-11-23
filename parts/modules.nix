{
  config,
  lib,
  moduleWithSystem,
  ...
}:
let
  cfg = config.fp-lib.modules;

  inherit (lib)
    mapAttrs
    mapAttrs'
    nameValuePair
    removeSuffix
    ;

  generateModule =
    modulePathes:
    moduleWithSystem (
      { config }:
      { ... }:
      {
        imports = modulePathes;
      }
    );

  listFilesInModuleDir =
    baseDir: moduleName: lib.attrNames (builtins.readDir "${toString baseDir}/${moduleName}");

  getFilesForModule =
    baseDir: fileType: moduleName:
    if fileType == "directory" then
      map (name: "${toString baseDir}/${moduleName}/${name}") (listFilesInModuleDir baseDir moduleName)
    else
      [ "${toString baseDir}/${moduleName}" ];

  # Generates modules for all files in the given baseDir
  generateModules =
    baseDir:
    generateModuleName (
      mapAttrs (moduleName: fileType: generateModule (getFilesForModule baseDir fileType moduleName)) (
        getLoadableModules baseDir
      )
    );

  generatePrivateModules =
    baseDir:
    mapAttrs' (name: value: nameValuePair "${cfg.privateNamePrefix}-${name}" value) (
      generateModules baseDir
    );

  # Gets the name of a object that can be loaded via import
  getLoadableModules =
    dir: (lib.filterAttrs (name: type: name != "default.nix") (builtins.readDir dir));

  # Modules are either in a folder with <name>.nix or in a folder <name>
  generateModuleName = mapAttrs' (name: value: nameValuePair (removeSuffix ".nix" name) value);

  nixosModules =
    (lib.optionalAttrs (cfg.nixos.public != null) (generateModules cfg.nixos.public))
    // (lib.optionalAttrs (cfg.privateNamePrefix != null && cfg.nixos.private != null) (
      generatePrivateModules cfg.nixos.private
    ));

  home-managerModules =
    (lib.optionalAttrs (cfg.home-manager.public != null) (generateModules cfg.home-manager.public))
    // (lib.optionalAttrs (cfg.privateNamePrefix != null && cfg.home-manager.private != null) (
      generatePrivateModules cfg.home-manager.private
    ));
in
{
  flake = {
    flakeModules.nixos = nixosModules;
    flakeModules.home-manager = home-managerModules;
    inherit nixosModules;
  };
}
