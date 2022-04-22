{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot = {
    initrd.availableKernelModules = [ "ata_piix" "mptsas" "floppy" ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    zfs.devNodes = "/dev/";
    zfs.extraPools = [ "zbackup" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    extraModprobeConfig = ''
      options zfs zfs_arc_min=104857600
      options zfs zfs_arc_max=209715200
    '';
    supportedFilesystems = [ "zfs" ];
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };
  };

  networking.hostName = "backup";
  networking.hostId = "5e9aced4";

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/245619d4-3928-4015-8ed3-3d60a9c54e2a";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/ca11b8b3-dc96-4ae3-b9da-4ef8f8557701";
      fsType = "ext4";
    };

  swapDevices = [{ device = "/dev/disk/by-uuid/70c51df2-8c10-4fe1-a083-f1eb5caf43e0"; }];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
