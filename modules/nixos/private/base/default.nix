{ pkgs, lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  documentation = {
    doc.enable = mkDefault false;
    nixos.enable = mkDefault false;
    info.enable = mkDefault false;
  };

  system.stateVersion = mkDefault "23.05";

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";
  console = {
    earlySetup = true;
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  boot = {
    tmp.useTmpfs = mkDefault true;
    tmp.cleanOnBoot = true;
    swraid.enable = mkDefault false;
    enableContainers = false;
  };
  environment.systemPackages = [ pkgs.vim ];

  services = {
    lvm.enable = false;
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';
    dbus.implementation = "broker";
  };
  security.wrapperDirSize = "10M";
}
