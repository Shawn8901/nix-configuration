{ self, ... }@inputs:
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd.availableKernelModules =
      [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" ];
    initrd.kernelModules = [ ];
    initrd.systemd.enable = true;
    kernelModules = [ ];
    kernelParams = [ "elevator=none" ];
    kernelPackages = pkgs.linuxPackages;
    extraModulePackages = [ ];
    zfs.devNodes = "/dev/";
    zfs.extraPools = [ "zbackup" ];
    zfs.requestEncryptionCredentials = false;
    extraModprobeConfig = ''
      options zfs zfs_arc_max=209715200
    '';
    supportedFilesystems = [ "zfs" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9de45e18-29e7-4330-b5ab-8a272f87aa36";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/fdf6956a-9418-4da8-9702-45c8a670a0eb"; }];

  hardware.cpu.intel.updateMicrocode = true;
}
