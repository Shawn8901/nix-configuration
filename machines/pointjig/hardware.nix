{ config, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  nixpkgs.hostPlatform.system = "x86_64-linux";

  boot = {
    initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    kernelModules = [ ];
    kernelPackages = pkgs.linuxPackages;
    extraModulePackages = [ ];
    kernelParams = [ "memhp_default_state=online" ];
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/03dd5cae-8689-4b89-9c73-854ba799f2fd";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/E588-9EBB";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/d9ea5a2c-63a9-4ec3-9168-977a6898c722"; }];


  hardware.cpu.intel.updateMicrocode = true;
}
