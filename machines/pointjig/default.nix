{ self, config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  networking = {
    firewall = {
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 80 443 9443 ];
    };
    networkmanager.enable = false;
    dhcpcd.enable = false;
  };

  systemd.network = {
    enable = true;
    networks = {
      "20-wired" = {
        matchConfig.Name = "enp1s0";
        networkConfig.DHCP = "yes";
        networkConfig.Domains = "fritz.box ~box ~.";
      };
    };
  };

  environment.systemPackages = with pkgs; [
  ];

  services = {
    openssh.enable = true;
    resolved.enable = true;
    mimir.enable = true;
    nginx.enable = true;
  };
  security.rtkit.enable = true;

  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  sound.enable = false;

  # remove bloatware (NixOS HTML file)
  documentation.nixos.enable = false;

  system.stateVersion = "21.11";
}
