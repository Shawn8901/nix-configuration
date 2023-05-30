{
  config,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix") (modulesPath + "/profiles/minimal.nix")];

  boot = {
    initrd.availableKernelModules = ["ata_piix" "uhci_hcd"];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    zfs.devNodes = "/dev/";
    zfs.extraPools = ["zbackup"];
    zfs.requestEncryptionCredentials = false;
    extraModprobeConfig = ''
      options zfs zfs_arc_max=209715200
    '';
    supportedFilesystems = ["zfs"];
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };
  };

  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
  '';

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9de45e18-29e7-4330-b5ab-8a272f87aa36";
    fsType = "ext4";
  };

  swapDevices = [{device = "/dev/disk/by-uuid/fdf6956a-9418-4da8-9702-45c8a670a0eb";}];

  hardware.cpu.intel.updateMicrocode = true;
}
