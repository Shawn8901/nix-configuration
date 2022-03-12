{ self, config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ./home
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-9.4.4"
  ];

  networking = {
    firewall = {
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ 9811 9090 ];
    };
    networkmanager.enable = false;
    dhcpcd.enable = false;
  };

  systemd.network = {
    enable = true;
    netdevs = {
      "br0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
          MACAddress = "02:49:35:0E:B9:39";
        };
      };
    };
    networks = {
      "br0" = {
        matchConfig.Name = "enp*";
        networkConfig.Bridge = "br0";
      };
      "bridge-br0" = {
        matchConfig.Name = "br0";
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
    glxinfo
    vulkan-tools
    cifs-utils
    alsa-utils
    xdg-utils

    OVMF
    python3
    python3Packages.pip

    gnomeExtensions.caffeine
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.screenshot-tool
    gnomeExtensions.remmina-search-provider
  ];

  fonts.fonts = with pkgs; [
    roboto
    font-awesome
    corefonts
  ];

  services = {
    xserver = {
      enable = true;
      layout = "de";
      displayManager.gdm.enable = true;
      desktopManager.gnome = {
        enable = true;
        favoriteAppsOverride = ''
          [org.gnome.shell]
          favorite-apps=[ "firefox.desktop", "org.gnome.Nautilus.desktop", "steam.desktop", "discord.desktop", "teamspeak.desktop" ,"org.keepassxc.KeePassXC.desktop"]
        '';
        extraGSettingsOverrides = ''
          [org.gnome.desktop.wm.preferences]
          button-layout=":minimize,maximize,close"
        '';
      };
    };
    gnome = {
      gnome-keyring.enable = true;
      gnome-remote-desktop.enable = false;
      #experimental-features.realtime-scheduling = true;
      evolution-data-server.enable = true;
      gnome-online-accounts.enable = true;
    };
    openssh.enable = true;
    resolved.enable = true;

    zfs.autoScrub.enable = true;
    zfs.trim.enable = true;

    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      media-session.enable = false;
      wireplumber.enable = true;
    };
    printing = {
      enable = true;
      drivers = [ pkgs.epson-escpr2 ];
    };
    zrepl = {
      enable = true;
      settings = {
        global = {
          monitoring = [
            {
              type = "prometheus";
              listen = ":9811";
              listen_freebind = true;
            }
          ];
        };
        jobs = [
          {
            name = "userdata";
            type = "push";
            filesystems = {
              "rpool/userdata<" = true;
              "rpool/userdata/steamlibrary" = false;
            };
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            send = {
              encrypted = false;
            };
            connect = {
              type = "tls";
              address = "tank:8888";
              ca = "/etc/zrepl/tank.crt";
              cert = "/etc/zrepl/pointalpha.crt";
              key = "/etc/zrepl/pointalpha.key";
              server_cn = "tank";
            };
            pruning = {
              keep_sender = [
                {
                  type = "not_replicated";
                }
                {
                  type = "last_n";
                  count = 10;
                }
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 12x1h | 7x1d";
                  regex = "^pointalpha_root_.*";
                }
              ];
              keep_receiver = [
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 24x1h | 35x1d | 6x30d | 1x365d";
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
        ];
      };
    };
  };
  security.rtkit.enable = true;

  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = true;
  hardware.sane.enable = true;
  sound.enable = false;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      qemu.package = pkgs.qemu_kvm;
      qemu.ovmf.enable = true;
    };
  };

  users.mutableUsers = false;
  users.users.root.hashedPassword = config.my.secrets.root.hashedPassword;

  nix.settings.trusted-users = [ "shawn" ];
  users.users.shawn = {
    hashedPassword = config.my.secrets.shawn.hashedPassword;
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "libvirtd" "plugdev" "adbusers" "scanner" "lp" ];
    uid = 1000;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
  };

  systemd.tmpfiles.rules = [ "d /media/nas 0750 shawn users -" ];

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

  programs.steam.enable = true;
  programs.dconf.enable = true;
  programs.adb.enable = true;
  programs.noisetorch.enable = true;
  programs.evolution.enable = true;

  environment = {
    variables.EDITOR = "nano";
    gnome.excludePackages = with pkgs.gnome; [
      totem
      cheese
    ] ++ (with pkgs; [
      epiphany
    ]);

    etc."zrepl/pointalpha.key".text = config.my.secrets.zrepl.certificates.pointalpha.private;
    etc."zrepl/pointalpha.crt".text = config.my.secrets.zrepl.certificates.pointalpha.public;
    etc."zrepl/tank.crt".text = config.my.secrets.zrepl.certificates.tank.public;
  };

  # remove bloatware (NixOS HTML file)
  documentation.nixos.enable = false;

  system.stateVersion = "22.05";
}
