{ self, ... }@inputs:
{ config, lib, pkgs, modulesPath, ... }:
let
  zfsOptions = [ "zfsutil" "X-mount.mkdir" ];
in {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "sd_mod" "sr_mod" ];
      kernelModules = [ "amdgpu" ];
    };
    kernelModules = [ "kvm-amd" "cifs" "usb_storage" ];
    kernelParams = [ "elevator=none" ];
    kernelPackages = pkgs.linuxPackages_zen;
    /*
    kernelPatches = [
      {
        name = "enable RT_FULL";
        patch = null;
        structuredExtraConfig = with lib; with lib.kernel; {
          PREEMPT = mkForce yes;
          PREEMPT_BUILD = mkForce yes;
          PREEMPT_VOLUNTARY = mkForce no;
          PREEMPT_COUNT = mkForce yes;
          PREEMPTION = mkForce yes;
        };
      }
      {
        name = "disable unused modules";
        patch = null;
        structuredExtraConfig = with lib; with lib.kernel; {
          KERNEL_XZ = mkForce no;
          HAVE_KERNEL_ZSTD = mkForce yes;
          KERNEL_ZSTD = mkForce yes;
          CONFIG_RD_ZSTD = mkForce yes;
          CONFIG_MODULE_COMPRESS_ZSTD = mkForce yes;
          CONFIG_CRYPTO_ZSTD = mkForce yes;

          INFINIBAND = mkForce no;

          AFFS_FS = mkForce no;
          AFS_FS = mkForce no;
          EROFS_FS = mkForce no;
          F2FS_FS = mkForce no;
          NILFS2_FS = mkForce no;
          REISERFS_FS = mkForce no;
          ORANGEFS_FS = mkForce no;
          JFS_FS = mkForce no;
          XFS_FS = mkForce no;
          QNX6FS_FS = mkForce no;
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
          "9P_FS" = mkForce no;

          ISDN = mkForce no;
          XEN = mkForce no;

          MEDIA_DIGITAL_TV_SUPPORT = mkForce no;
          MEDIA_ANALOG_TV_SUPPORT = mkForce no;
          VIDEO_STK1160_COMMON = mkForce no;
          LIRC = mkForce no;
          ANDROID = mkForce no;

          CHROME_PLATFORMS = mkForce no;
          SURFACE_PLATFORMS = mkForce no;
          INPUT_TOUCHSCREEN = mkForce no;
          ARCH_TEGRA = mkForce no;
          BLK_DEV_MD = mkForce no;
          DM_RAID = mkForce no;
          MD = mkForce no;
          HYPERV = mkForce no;

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
          FB_SIS = mkForce no;
          FB_SIS_300 = mkForce no;
          FB_SIS_315 = mkForce no;
          FB_3DFX_ACCEL = mkForce no;
        };
      }
    ];
    */
    extraModulePackages = [ ];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=6442450944
    '';
    supportedFilesystems = [ "zfs" "ntfs" ];
    kernel.sysctl = { "vm.swappiness" = lib.mkDefault 1; };
    zfs.devNodes = "/dev/disk/by-id";
  };

  fileSystems."/" = {
    device = "rpool/local/root";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/var/log" = {
    device = "rpool/local/log";
    fsType = "zfs";
    options = zfsOptions;
    neededForBoot = true;
  };

  fileSystems."/persist" = {
    device = "rpool/safe/persist";
    fsType = "zfs";
    options = zfsOptions;
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/home" = {
    device = "rpool/safe/home";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/steamlibrary" = {
    device = "rpool/local/steamlibrary";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F66B-A20D";
    fsType = "vfat";
    options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" ];
  };

  swapDevices = [ ];

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
}
