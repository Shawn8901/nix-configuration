{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  zfsOptions = ["zfsutil" "X-mount.mkdir"];
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  #nix.settings.system-features = ["gccarch-x86-64-v3" "benchmark" "big-parallel" "kvm" "nixos-test"];
  nixpkgs.hostPlatform = {
    #gcc.arch = "x86-64-v3";
    system = "x86_64-linux";
  };

  boot = {
    initrd.availableKernelModules = ["ahci" "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod"];
    kernelModules = ["kvm-intel" "cifs" "snd_pcsp"];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    extraModulePackages = [];
    extraModprobeConfig = ''
      options zfs zfs_arc_min=1073741824
      options zfs zfs_arc_max=2147483648
    '';

    supportedFilesystems = ["zfs" "ntfs"];
    zfs.devNodes = "/dev/disk/by-id";
    zfs.extraPools = ["ztank"];
    zfs.requestEncryptionCredentials = ["ztank"];
    postBootCommands = lib.mkAfter ''
      ${pkgs.zfs}/bin/zfs mount -a
    '';
  };

  fileSystems."/" = {
    device = "rpool/local/root";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/persist" = {
    device = "rpool/safe/persist";
    fsType = "zfs";
    options = zfsOptions;
    neededForBoot = true;
  };

  fileSystems."/var/log" = {
    device = "rpool/local/log";
    fsType = "zfs";
    options = zfsOptions;
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "rpool/safe/home";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/persist/var/lib/nextcloud/data" = {
    device = "ztank/replica/nextcloud";
    fsType = "zfs";
    options = zfsOptions ++ ["noauto"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/605D-0B3B";
    fsType = "vfat";
    options = ["x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto"];
  };

  swapDevices = [{device = "/dev/disk/by-uuid/63c7d09e-c829-400d-904d-4753b89358ee";}];

  hardware.cpu.intel.updateMicrocode = true;
}
