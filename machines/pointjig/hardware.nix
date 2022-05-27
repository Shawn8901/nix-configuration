{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules =
    [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  boot.kernel.sysctl = { "vm.swappiness" = lib.mkDefault 10; };

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/vda";
  };

  networking.hostName = "pointjig";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/51da7486-bbd6-478d-8b91-6097e8f0490f";
    fsType = "ext4";
  };

  swapDevices = [ ];
}
