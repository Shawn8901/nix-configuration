{ pkgs, lib, ... }:
let inherit (lib.kernel) yes no;
in pkgs.linux_xanmod_stable.override (finalAttrs: {
  structuredExtraConfig = finalAttrs.structuredExtraConfig // {
    GENERIC_CPU = no;
    GENERIC_CPU3 = yes;
  };
})
