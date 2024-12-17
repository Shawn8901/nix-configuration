{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  zfsOptions = [
    "zfsutil"
    "X-mount.mkdir"
  ];
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nix.settings.system-features = [
    "gccarch-x86-64-v3"
    "benchmark"
    "big-parallel"
    "kvm"
    "nixos-test"
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sr_mod"
      ];
      postResumeCommands = lib.mkAfter ''
        ${pkgs.zfs}/bin/zfs mount -a
      '';
    };
    kernelModules = [
      "kvm-intel"
      "cifs"
    ];
    kernelPackages = pkgs.linuxPackages;
    extraModulePackages = with config.boot.kernelPackages; [ it87 ];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=2147483648
      options it87 ignore_resource_conflict=1 force_id=0x862
    '';

    supportedFilesystems = [
      "zfs"
      "ntfs"
    ];
    zfs = {
      devNodes = "/dev/disk/by-id";
      extraPools = [ "ztank" ];
      requestEncryptionCredentials = [ "ztank" ];
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    tmp.useTmpfs = false;
  };

  fileSystems = {
    "/" = {
      device = "rpool/local/root";
      fsType = "zfs";
      options = zfsOptions;
    };

    "/nix" = {
      device = "rpool/local/nix";
      fsType = "zfs";
      options = zfsOptions;
    };

    "/persist" = {
      device = "rpool/safe/persist";
      fsType = "zfs";
      options = zfsOptions;
      neededForBoot = true;
    };

    "/var/log" = {
      device = "rpool/local/log";
      fsType = "zfs";
      options = zfsOptions;
      neededForBoot = true;
    };

    "/home" = {
      device = "rpool/safe/home";
      fsType = "zfs";
      options = zfsOptions;
    };

    "/persist/var/lib/nextcloud/data" = {
      device = "ztank/replica/nextcloud";
      fsType = "zfs";
      options = zfsOptions;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/605D-0B3B";
      fsType = "vfat";
      options = [
        "x-systemd.idle-timeout=1min"
        "x-systemd.automount"
        "noauto"
      ];
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/63c7d09e-c829-400d-904d-4753b89358ee"; } ];

  hardware.cpu.intel.updateMicrocode = true;
}
