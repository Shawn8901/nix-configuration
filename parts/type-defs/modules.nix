{ lib, ... }:
let
  inherit (lib) mkOption types genAttrs;

  moduleDirOption = mkOption {
    type = types.nullOr types.path;
    description = "Path to the module dir";
    default = null;
  };
in
{
  options = {
    fp-lib = {
      modules =
        let
          generateModuleDef =
            genAttrs
              [
                "nixos"
                "home-manager"
              ]
              (_: {
                public = moduleDirOption;
                private = moduleDirOption;
              });
        in
        generateModuleDef
        // {
          privateNamePrefix = mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
    };
  };
}
