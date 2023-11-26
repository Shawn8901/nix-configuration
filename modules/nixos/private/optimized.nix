{ inputs', config, lib, pkgs, ... }:
let

  unoptimized = inputs'.nixpkgs.legacyPackages;
  inherit (lib) mkEnableOption mkIf;

  cfg = config.shawn8901.optimized;
in {
  options = {
    shawn8901.optimized = {
      enable = mkEnableOption
        "use optimized x86-64_v3 and other to reduce build amount";
    };
  };
  config = mkIf cfg.enable {

    # In case someone comes around, please be aware that the system feature "gccarch-x86-64-v3"
    # has to be available on the builder before it can build for x86-64_v3
    nix.settings.system-features =
      [ "gccarch-x86-64-v3" "benchmark" "big-parallel" "kvm" "nixos-test" ];
    nixpkgs.hostPlatform.gcc.arch = "x86-64-v3";

    nixpkgs.config.packageOverrides = pkgs: {
      inherit (unoptimized) openexr_3;
      haskellPackages = pkgs.haskellPackages.override {
        overrides = haskellPackagesNew: haskellPackagesOld: {
          inherit (unoptimized.haskellPackages)
            cryptonite hermes-json hermes-json_0_2_0_1;
        };
      };

      krita = unoptimized.krita;
      libreoffice-qt = unoptimized.libreoffice-qt;
      portfolio = unoptimized.portfolio;

      udisks2 = pkgs.udisks2.override {
        btrfs-progs = null;
        nilfs-utils = null;
        xfsprogs = null;
        f2fs-tools = null;
      };

      partition-manager = pkgs.partition-manager.override {
        btrfs-progs = null;
        e2fsprogs = null;
        f2fs-tools = null;
        hfsprogs = null;
        jfsutils = null;
        nilfs-utils = null;
        reiser4progs = null;
        reiserfsprogs = null;
        udftools = null;
        xfsprogs = null;
      };
    };
  };
}
