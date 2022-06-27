{ self, ... }@inputs:
let
  pkgs = inputs.nixpkgs-stable.legacyPackages.x86_64-linux;
  unfree-pkgs = import inputs.nixpkgs-stable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

  baseKernel = pkgs.linuxKernel.kernels.linux_zen;
in {

  s25rttr = pkgs.callPackage ./s25rttr {
    SDL2 = pkgs.SDL2.override { withStatic = true; };
  };
  proton-ge-custom = pkgs.callPackage ./proton-ge-custom { };
  epson-escpr2 = pkgs.callPackage ./epson-escpr2 { };
  stfc = pkgs.callPackage ./shellscripts/stfc.nix { };
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = pkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix { };

  linux_zen_rt = baseKernel.override ({
    argsOverride =  {
      ignoreConfigErrors = true;
      structuredExtraConfig = with pkgs.lib; with pkgs.lib.kernel; {
        PREEMPT = mkForce yes;
        PREEMPT_BUILD = mkForce yes;
        PREEMPT_VOLUNTARY = mkForce no;
        PREEMPT_COUNT = mkForce yes;
        PREEMPTION = mkForce yes;

        INFINIBAND = mkForce no;

        REISERFS_FS = mkForce no;
        JFS_FS = mkForce no;
        XFS_FS = mkForce no;
        MINIX_FS = mkForce no;
        ROMFS_FS = mkForce no;
        ADFS_FS = mkForce no;
        HFS_FS = mkForce no;
        HFSPLUS_FS = mkForce no;
        BEFS_FS = mkForce no;
        BFS_FS = mkForce no;
        EFS_FS = mkForce no;
        JFFS2_FS = mkForce no;
        CRAMFS = mkForce no;
        VXFS_FS = mkForce no;
        HPFS_FS = mkForce no;
        QNX4FS_FS = mkForce no;
        SYSV_FS = mkForce no;
        UFS_FS = mkForce no;

        ISDN = mkForce no;
        XEN = mkForce no;

        MEDIA_DIGITAL_TV_SUPPORT = mkForce no;
        MEDIA_ANALOG_TV_SUPPORT = mkForce no;
        VIDEO_STK1160_COMMON = mkForce no;
        LIRC = mkForce no;
        ANDROID = mkForce no;

        CHROME_PLATFORMS = mkForce no;

        VGA_SWITCHEROO = mkForce no;
        DRM_GMA500 = mkForce no;
        DRM_GMA600 = mkForce no;
        DRM_GMA3600 = mkForce no;
        DRM_VMWGFX_FBCON = mkForce no;
        DRM_I915_GVT = mkForce no;
        DRM_I915_GVT_KVMGT = mkForce no;

        FB_NVIDIA_I2C = mkForce no;
        FB_RIVA_I2C = mkForce no;
        FB_ATY_CT = mkForce no;
        FB_ATY_GX = mkForce no;
        FB_SAVAGE_I2C = mkForce no;
        FB_SAVAGE_ACCEL = mkForce no;
        FB_SIS_300 = mkForce no;
        FB_SIS_315 = mkForce no;
        FB_3DFX_ACCEL = mkForce no;
      };
    };
  });

  agenix = inputs.agenix.defaultPackage.x86_64-linux;
}
