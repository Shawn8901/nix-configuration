{ pkgs, lib, ... }:
let
  inherit (lib) mkForce;
  inherit (lib.kernel) yes no;
in
pkgs.linux_xanmod.override (finalAttrs: {
  structuredExtraConfig = finalAttrs.structuredExtraConfig // {
    GENERIC_CPU = no;
    GENERIC_CPU3 = yes;

    BTRFS_FS = mkForce no;
    BCACHEFS_FS = mkForce no;
    REISERFS_FS = mkForce no;
    JFS_FS = mkForce no;
    XFS_FS = mkForce no;
    GFS2_FS = mkForce no;
    OCFS2_FS = mkForce no;
    NILFS2_FS = mkForce no;
    F2FS_FS = mkForce no;
    ZONEFS_FS = mkForce no;

    XEN = mkForce no;
    NFC = mkForce no;
    CAN = mkForce no;
    PCCARD = mkForce no;
    GNSS = mkForce no;

    FIREWIRE = mkForce no;
    W1 = mkForce no;
    DRM_RADEON = mkForce no;
    DRM_I915 = mkForce no;
    DRM_GMA500 = mkForce no;
    DRM_AST = mkForce no;
    DRM_MGAG200 = mkForce no;
    DRM_ACCEL_HABANALABS = mkForce no;
    DRM_ACCEL_IVPU = mkForce no;
    DRM_ACCEL_QAIC = mkForce no;

    MEMSTICK = mkForce no;
    INFINIBAND = mkForce no;
    GREYBUS = mkForce no;
    SOUNDWIRE = mkForce no;
    HTE = yes;

    AD525X_DPOT = mkForce no;
  };
})
