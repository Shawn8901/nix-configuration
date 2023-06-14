{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: let
  zfsOptions = ["zfsutil" "X-mount.mkdir"];
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "rtsx_pci_sdmmc" "usbhid" "sd_mod" "sr_mod"];
      kernelModules = ["amdgpu"];
      systemd.enable = true;
    };
    kernelModules = ["amdgpu" "kvm-amd" "cifs" "usb_storage" "acpi_call" "amdgpu" "amd_pstate"];
    kernelPackages = pkgs.linuxPackages_xanmod;
    kernelParams = ["initcall_blacklist=acpi_cpufreq_init" "amd_pstate=passive" "amd_pstate.shared_mem=1" "amdgpu.dcfeaturemask=0x8"];
    extraModulePackages = with config.boot.kernelPackages; [zenpower];
    blacklistedKernelModules = ["k10temp"];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=1610612736
    '';
    supportedFilesystems = ["zfs" "ntfs"];
    kernel.sysctl = {"vm.swappiness" = lib.mkDefault 1;};
    zfs.devNodes = "/dev/disk/by-id";
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/" = {
    device = "rpool/local/root";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/var/log" = {
    device = "rpool/local/log";
    fsType = "zfs";
    options = zfsOptions;
    neededForBoot = true;
  };

  fileSystems."/persist" = {
    device = "rpool/safe/persist";
    fsType = "zfs";
    options = zfsOptions;
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
    options = zfsOptions;
  };

  fileSystems."/home" = {
    device = "rpool/safe/home";
    fsType = "zfs";
    options = zfsOptions;
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = ["x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto"];
  };
  swapDevices = [{device = "/dev/disk/by-label/swap";}];

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  powerManagement.enable = true;
}
