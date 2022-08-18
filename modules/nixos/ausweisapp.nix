inputs:
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ausweisapp;

in
{
  options.programs.ausweisapp = {
    enable = mkOption {
      description = ''
        Whether to enable AusweisApp2.
      '';
      default = false;
      type = lib.types.bool;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.AusweisApp2;
      defaultText = literalExpression "pkgs.AusweisApp2";
      description = "Which package to use for AusweisApp2";
    };
    openFirewall = mkOption {
      description = ''
        Whether to open the required firewall ports for the Smartphone as Card Reader (SaC) functionality of AusweisApp2.
      '';
      default = false;
      type = lib.types.bool;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    networking.firewall.allowedUDPPorts = lib.optionals cfg.openFirewall [ 24727 ];
  };
}
