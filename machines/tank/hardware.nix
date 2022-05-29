{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules =
      [ "ahci" "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" "cifs" "snd_pcsp" ];
    extraModulePackages = [ ];
    extraModprobeConfig = ''
      options zfs zfs_arc_min=6442450944
      options zfs zfs_arc_max=10737418240
    '';

    supportedFilesystems = [ "zfs" "ntfs" ];
    zfs.devNodes = "/dev/disk/by-id";
    zfs.extraPools = [ "ztank" ];
    zfs.requestEncryptionCredentials = [ "ztank" ];

    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    kernel.sysctl = { "vm.swappiness" = lib.mkDefault 10; };
    postBootCommands = ''
      ${pkgs.zfs}/bin/zfs mount -a
    '';
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "rpool/nixos/nix";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/etc" = {
    device = "rpool/nixos/etc";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/var" = {
    device = "rpool/nixos/var";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/var/lib" = {
    device = "rpool/nixos/var/lib";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/var/log" = {
    device = "rpool/nixos/var/log";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/home" = {
    device = "rpool/userdata/home";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/home/shawn" = {
    device = "rpool/userdata/home/shawn";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/home/ela" = {
    device = "rpool/userdata/home/ela";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/root" = {
    device = "rpool/userdata/home/root";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" ];
  };

  fileSystems."/var/lib/nextcloud/data" = {
    device = "ztank/replica/nextcloud";
    fsType = "zfs";
    options = [ "zfsutil" "X-mount.mkdir" "noauto" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/605D-0B3B";
    fsType = "vfat";
    options = [ "x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto" ];
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/63c7d09e-c829-400d-904d-4753b89358ee"; }];

  hardware.cpu.intel.updateMicrocode = true;
}
