{ self, config, pkgs, lib, inputs, modulesPath, ... }:
let
  secrets = config.age.secrets;
  system = pkgs.hostPlatform.system;
in
{
  imports = [];


  age.secrets = {
  };

  networking = {
    firewall = {
    };
    networkmanager.enable = false;
    dhcpcd.enable = false;
    useNetworkd = true;
    useDHCP = false;
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "enp6s18";
        };
      };
    };
  };

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };
    resolved.enable = true;
    fail2ban = {
      enable = true;
      maxretry = 5;
    };
    vnstat.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=100M
    '';
    acpid.enable = true;
  };
  security.auditd.enable = false;
  security.audit.enable = false;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;

  users.mutableUsers = true;

  users.users.shawn = {
    password = "";
    isNormalUser = true;
    group = "shawn";
  };
  users.groups.shawn = {};
}
