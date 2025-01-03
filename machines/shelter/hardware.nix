{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
    ];
    kernelPackages = pkgs.linuxPackages;
    zfs = {
      devNodes = "/dev/";
      extraPools = [ "zbackup" ];
      requestEncryptionCredentials = false;
    };
    extraModprobeConfig = ''
      options zfs zfs_arc_max=134217728
    '';
    supportedFilesystems = [ "zfs" ];
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9de45e18-29e7-4330-b5ab-8a272f87aa36";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/fdf6956a-9418-4da8-9702-45c8a670a0eb"; } ];

  hardware.cpu.intel.updateMicrocode = true;
}
