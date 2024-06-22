{
  self',
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  inherit (pkgs.linuxKernel) packagesFor;
  zfsOptions = [
    "zfsutil"
    "X-mount.mkdir"
  ];
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "sd_mod"
        "sr_mod"
      ];
      systemd.enable = true;
    };
    kernelModules = [
      "kvm-amd"
      "cifs"
      "usb_storage"
      "k10temp"
      "ntsync"
    ];
    kernelPackages = packagesFor self'.packages.linux_xanmod_x86_64_v3;
    extraModprobeConfig = ''
      options zfs zfs_arc_max=6442450944
      options nct6775 force_id=0xd420
    '';
    supportedFilesystems = [
      "zfs"
      "ntfs"
    ];
    kernel.sysctl = {
      "vm.swappiness" = lib.mkDefault 1;
    };
    zfs.devNodes = "/dev/disk/by-id";

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "rpool/local/root";
      fsType = "zfs";
      options = zfsOptions;
    };

    "/var/log" = {
      device = "rpool/local/log";
      fsType = "zfs";
      options = zfsOptions;
      neededForBoot = true;
    };

    "/persist" = {
      device = "rpool/safe/persist";
      fsType = "zfs";
      options = zfsOptions;
      neededForBoot = true;
    };

    "/nix" = {
      device = "rpool/local/nix";
      fsType = "zfs";
      options = zfsOptions;
    };

    "/home" = {
      device = "rpool/safe/home";
      fsType = "zfs";
      options = zfsOptions;
    };

    "/steamlibrary" = {
      device = "rpool/local/steamlibrary";
      fsType = "zfs";
      options = zfsOptions;
    };

    "/boot" = {
      device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
      options = [
        "x-systemd.idle-timeout=1min"
        "x-systemd.automount"
        "noauto"
      ];
    };
  };

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
}
