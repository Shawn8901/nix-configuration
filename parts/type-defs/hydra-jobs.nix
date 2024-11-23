{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
  inherit (flake-parts-lib) mkTransposedPerSystemModule;
in
mkTransposedPerSystemModule {
  file = ./hydra-jobs.nix;

  name = "hydraJobs";
  option = mkOption {
    type = types.attrsOf types.unspecified;
    default = { };
  };
}
