{ lib, flake-parts-lib, ... }:
let
  inherit (lib) mkOption types literalExpression;
  inherit (flake-parts-lib) mkSubmoduleOptions;
in {
  options = {
    flake = mkSubmoduleOptions {
      flakeModules = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
      };
      modules = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
      };
    };
  };
}
