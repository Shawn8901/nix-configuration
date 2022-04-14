{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
    initrd.kernelModules = [ "amdgpu" ];
    kernelModules = [ "kvm-amd" "cifs" ];
    extraModulePackages = [ ];

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    supportedFilesystems = [ "zfs" "ntfs" ];
    zfs.devNodes = "/dev/disk/by-id";

    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    kernel.sysctl = {
      "vm.swappiness" = lib.mkDefault 1;
    };
  };

  networking.hostName = "pointalpha";
  networking.hostId = "a642f2c0";

  services.xserver.videoDrivers = [ "amdgpu" ];

  fileSystems."/" =
    {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "mode=755" ];
    };

  fileSystems."/nix" =
    {
      device = "rpool/nixos/nix";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

  fileSystems."/etc" =
    {
      device = "rpool/nixos/etc";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

  fileSystems."/var" =
    {
      device = "rpool/nixos/var";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

  fileSystems."/var/lib" =
    {
      device = "rpool/nixos/var/lib";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

  fileSystems."/var/log" =
    {
      device = "rpool/nixos/var/log";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

  fileSystems."/home" =
    {
      device = "rpool/userdata/home";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

  fileSystems."/home/shawn" =
    {
      device = "rpool/userdata/home/shawn";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

  fileSystems."/home/shawn/.steamlibrary" =
    {
      device = "rpool/userdata/steamlibrary";
      fsType = "zfs";
      options = [ "zfsutil" "X-mount.mkdir" ];
    };

  fileSystems."/root" =
    {
      device = "rpool/userdata/home/root";
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
