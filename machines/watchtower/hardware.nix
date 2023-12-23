{ modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];
  boot = {
    initrd.availableKernelModules =
      [ "xhci_pci" "virtio_pci" "virtio_scsi" "usbhid" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
  fileSystems = {
    "/" = {
      device = "/dev/sda2";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };
}
