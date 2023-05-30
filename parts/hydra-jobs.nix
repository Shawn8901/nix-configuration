{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (flake-parts-lib) mkTransposedPerSystemModule;
in
  mkTransposedPerSystemModule {
    name = "hydraJobs";
    option = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = {};
    };
    file = ./hydra-jobs.nix;
  }