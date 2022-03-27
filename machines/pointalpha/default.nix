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
    extraHosts = ''
      192.168.11.12 portainer.pointjig.local 
      192.168.11.12 edge.pointjig.local
    '';
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

  environment.systemPackages = with pkgs; [
    glxinfo
    vulkan-tools
    cifs-utils
    alsa-utils
    xdg-utils
    libva-utils

    plasma5Packages.skanlite
    plasma5Packages.ark
    plasma5Packages.kate
    plasma5Packages.kdeplasma-addons
    plasma5Packages.xdg-desktop-portal-kde
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

      displayManager.sddm.enable = true;
      displayManager.defaultSession = "plasmawayland";
      desktopManager.plasma5 = {
        enable = true;
        phononBackend = "vlc";
      };
      desktopManager.xterm.enable = false;
    };
    openssh.enable = true;
    resolved.enable = true;

    zfs.trim.enable = true;
    zfs.autoScrub.enable = true;
    zfs.autoScrub.pools = [ "rpool" ];

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
    udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
    '';
    avahi.enable = true;
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
    extraPackages = with pkgs; [ libva rocm-opencl-icd rocm-opencl-runtime ];
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "start";
      qemu.package = pkgs.qemu_kvm;
    };
  };

  users.mutableUsers = false;
  users.users.root.hashedPassword = config.my.secrets.root.hashedPassword;

  nix.settings.trusted-users = [ "shawn" ];
  users.users.shawn = {
    hashedPassword = config.my.secrets.shawn.hashedPassword;
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" "video" "audio" "libvirtd" "plugdev" "adbusers" "scanner" "lp" ];
    uid = 1000;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
  };

  systemd.tmpfiles.rules = [ "d /media/nas 0750 shawn users -" ];

  programs.steam.enable = true;
  programs.dconf.enable = true;
  programs.adb.enable = true;
  programs.noisetorch.enable = true;
  programs.ssh.startAgent = true;

  environment = {
    variables.AMD_VULKAN_ICD = "RADV";
    variables.EDITOR = "nano";
    variables.NIXOS_OZONE_WL = "1";

    etc."zrepl/pointalpha.key".text = config.my.secrets.zrepl.certificates.pointalpha.private;
    etc."zrepl/pointalpha.crt".text = config.my.secrets.zrepl.certificates.pointalpha.public;
    etc."zrepl/tank.crt".text = config.my.secrets.zrepl.certificates.tank.public;
  };

  # remove bloatware (NixOS HTML file)
  documentation.nixos.enable = false;

  system.stateVersion = "21.11";
}
