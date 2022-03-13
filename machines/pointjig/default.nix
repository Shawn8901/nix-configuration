{ self, config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  networking = {
    firewall = {
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 80 443 ];
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

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "de_DE.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  environment.systemPackages = with pkgs; [
    jq
    nano
    docker-compose
  ];

  services = {
    openssh.enable = true;
    resolved.enable = true;
  };
  security.rtkit.enable = true;

  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  sound.enable = false;
  virtualisation.docker.enable = true;


  users.mutableUsers = false;
  users.users.root = {
    hashedPassword = config.my.secrets.root.hashedPassword;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
  };
  users.users.shawn = {
    hashedPassword = config.my.secrets.shawn.hashedPassword;
    isNormalUser = true;
    group = "users";
    extraGroups = [ ];
    uid = 1000;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    enableGlobalCompInit = true;
    interactiveShellInit = ''
      neofetch
    '';
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "command-not-found" "cp" "zsh-interactive-cd" ];
      theme = "fletcherm";
    };
  };
  environment.pathsToLink = [ "/share/zsh" ];

  environment = {
    variables.EDITOR = "nano";
  };

  # remove bloatware (NixOS HTML file)
  documentation.nixos.enable = false;

  system.stateVersion = "21.11";
}
