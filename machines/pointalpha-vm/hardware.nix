{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  nix.settings.system-features = ["gccarch-x86-64-v2" "gccarch-x86-64-v3" "benchmark" "big-parallel" "kvm" "nixos-test"];
  nixpkgs.hostPlatform = {
    gcc.arch = "x86-64-v3";
    system = "x86_64-linux";
  };

  nixpkgs.config.replaceStdenv = {pkgs}: pkgs.withCFlags ["-mpclmul"] pkgs.stdenv;

  boot = {
    initrd = {
      availableKernelModules = ["ahci" "xhci_pci" "usbhid" "sd_mod" "sr_mod"];
      kernelModules = ["amdgpu"];
      systemd.enable = true;
    };
    kernelModules = ["amdgpu" "kvm-amd" "cifs" "usb_storage"];
    kernelPackages = pkgs.linuxPackages_xanmod;
    extraModulePackages = with config.boot.kernelPackages; [zenpower];
    blacklistedKernelModules = ["k10temp"];
    supportedFilesystems = ["ext4" "ntfs"];
    kernel.sysctl = {"vm.swappiness" = lib.mkDefault 1;};
    zfs.devNodes = "/dev/disk/by-id";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/ROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = ["x-systemd.idle-timeout=1min" "x-systemd.automount" "noauto"];
  };

  swapDevices = [];

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
}
