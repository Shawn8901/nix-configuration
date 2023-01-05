{ config, pkgs, lib, modulesPath, ... }:
let
  zfsOptions = [ "zfsutil" "X-mount.mkdir" ];
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nix.settings = {
    system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "gccarch-x86-64-v2" "gccarch-x86-64-v3" ];
    substituters = [ "http://tank.fritz.box/" ];
  };
  nixpkgs.hostPlatform = {
    #gcc.arch = "x86-64-v3";
    system = "x86_64-linux";
  };

  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "sd_mod" "sr_mod" ];
      kernelModules = [ "amdgpu" ];
      systemd.enable = true;
    };
    kernelModules = [ "amdgpu" "kvm-amd" "cifs" "usb_storage" ];
    kernelPackages = pkgs.linuxPackages_xanmod;
    extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
    blacklistedKernelModules = [
      "k10temp"
    ];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=6442450944
      options zfs zfs_vdev_scheduler=deadline
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
