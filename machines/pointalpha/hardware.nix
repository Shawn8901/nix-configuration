{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules =
      [ "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
    initrd.kernelModules = [ "amdgpu" ];
    kernelModules = [ "kvm-amd" "cifs" ];
    kernelParams = [ "elevator=none" ];
    extraModulePackages = [ ];
    extraModprobeConfig = ''
      options zfs zfs_arc_min=4294967296
      options zfs zfs_arc_max=4294967296
    '';

    supportedFilesystems = [ "zfs" "ntfs" ];
    zfs.devNodes = "/dev/disk/by-id";

    kernelPackages = pkgs.linuxPackages_zen;

    kernel.sysctl = { "vm.swappiness" = lib.mkDefault 1; };
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  fileSystems."/" = {
    device = "rpool/local/root";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/var/log" = {
    device = "rpool/local/log";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
    neededForBoot = true;
  };

  fileSystems."/persist" = {
    device = "rpool/safe/persist";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/home" = {
    device = "rpool/safe/home";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/steamlibrary" = {
    device = "rpool/local/steamlibrary";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F66B-A20D";
    fsType = "vfat";
    options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" ];
  };

  swapDevices = [ ];

  hardware.cpu.amd.updateMicrocode = true;
}
