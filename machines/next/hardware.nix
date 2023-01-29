{
  config,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  nixpkgs.hostPlatform.system = "x86_64-linux";

  boot = {
    initrd.availableKernelModules = ["uhci_hcd" "ehci_pci" "ahci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
    kernelModules = ["kvm-intel"];
    kernelPackages = pkgs.linuxPackages;
    extraModulePackages = [];
    kernelParams = ["memhp_default_state=online"];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6e32d049-bc7e-4382-b989-3c5eca7bc8ef";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1AFE-DFCF";
    fsType = "vfat";
  };

  swapDevices = [{device = "/dev/disk/by-uuid/6f049e18-ba0e-478b-a917-775abca0d3c2";}];

  hardware.cpu.intel.updateMicrocode = true;
}
