{
  lib,
  config,
  ...
}: {
  documentation = {
    man.enable = false;
  };

  system.autoUpgrade = {
    enable = true;
    dates = "07:00";
    flake = "github:shawn8901/nix-configuration";
    allowReboot = true;
    persistent = true;
  };

  fonts = {
    fontconfig.enable = lib.mkDefault false;
  };
  environment.noXlibs = true;

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
      ignoreIP = ["192.168.11.0/24"];
    };

    prometheus = let
      nodePort = toString config.services.prometheus.exporters.node.port;
    in {
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["localhost:${nodePort}"];
              labels = {machine = "${config.networking.hostName}";};
            }
          ];
        }
      ];
      exporters = {
        node = {
          enable = true;
          listenAddress = "localhost";
          port = 9101;
          enabledCollectors = ["systemd"];
        };
      };
    };
  };

  nix.gc.options = "--delete-older-than 3d";
}
