{ self, ... }@inputs:
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd = {
      availableKernelModules =
        [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" ];
      kernelModules = [ ];
      systemd.enable = true;
      systemd.contents = { "/etc/modprobe.d/nixos.conf".source = config.environment.etc."modprobe.d/nixos.conf".source; };
    };
    kernelModules = [ ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
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
