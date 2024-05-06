{
  inputs',
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkMerge
    mkDefault
    versionOlder
    optionalAttrs
    optionalString
    ;
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

  environment.sessionVariables.FLAKE = lib.mkDefault "github:shawn8901/nix-configuration";
  environment.systemPackages = [ pkgs.vim ];

  services = mkMerge [
    {
      lvm.enable = false;
      journald.extraConfig = ''
        SystemMaxUse=100M
        SystemMaxFileSize=50M
      '';
    }
    (optionalAttrs (!versionOlder config.system.nixos.release "24.05") {
      dbus.implementation = "broker";
    })
  ]

  ;
}
