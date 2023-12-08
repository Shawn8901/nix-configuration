{ inputs', config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf singleton const;

  cfg = config.shawn8901.server;
in {
  options = {
    shawn8901.server = { enable = mkEnableOption "server config for nixos"; };
  };
  config = mkIf cfg.enable {
    documentation = { man.enable = false; };

    # FIXME https://github.com/NixOS/nixpkgs/issues/265675
    nixpkgs = lib.optionalAttrs (config.environment.noXlibs) {
      overlays = singleton (const (super: {
        pipewire = super.pipewire.override {
          x11Support = false;
          ffadoSupport = false;
        };
      }));
    };

    system.autoUpgrade = {
      enable = true;
      dates = "05:14";
      flake = "github:shawn8901/nix-configuration";
      allowReboot = true;
      persistent = true;
    };

    networking = {
      firewall.logRefusedConnections = false;
      networkmanager.enable = false;
      nftables.enable = true;
      dhcpcd.enable = false;
      useNetworkd = true;
      useDHCP = lib.mkDefault false;
    };

    sound.enable = lib.mkDefault false;
    hardware.pulseaudio.enable = false;
    hardware.bluetooth.enable = false;
    security = {
      acme = {
        acceptTerms = true;
        defaults.email = lib.mkDefault "shawn@pointjig.de";
      };
    };

    services = {
      xserver.enable = false;
      qemuGuest.enable = true;
      resolved.enable = true;
      vnstat.enable = true;
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
      fail2ban = {
        enable = true;
        maxretry = 3;
        bantime = "1h";
        bantime-increment.enable = true;
        ignoreIP = [ "192.168.11.0/24" ];
      };
    };

    nix.gc.options = "--delete-older-than 2d";
  };
}
