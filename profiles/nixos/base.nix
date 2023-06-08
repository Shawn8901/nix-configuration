{
  inputs',
  pkgs,
  lib,
  ...
}: {
  documentation = {
    doc.enable = false;
    nixos.enable = false;
    info.enable = false;
    man = {
      enable = lib.mkDefault true;
      generateCaches = lib.mkDefault true;
    };
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  boot.tmp.cleanOnBoot = true;

  services.lvm.enable = false;

  environment.sessionVariables.FLAKE = lib.mkDefault "github:shawn8901/nix-configuration";
  environment.systemPackages = with pkgs;
    [
      git
      htop
      nano
      vim
      sops
    ]
    ++ [inputs'.nh.packages.default];

  services = {
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';
  };
}
