{ self, config, pkgs, lib, helpers, ... }:

{
  imports = [
    ./hardware.nix
    ./home.nix
  ];

  age.secrets = {
    zrepl_pointalpha = {
      file = ../../secrets/zrepl_pointalpha.age;
    };
    samba_credentials = {
      file = ../../secrets/samba_credentials.age;
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-9.4.4"
  ];

  networking = {
    firewall =
      let
        stronghold_range = { from = 2300; to = 2400; };
        stronghold_tcp = 47624;
      in
      {
        allowedUDPPortRanges = [ stronghold_range ];
        allowedTCPPorts = [ config.services.prometheus.port stronghold_tcp ];
        allowedTCPPortRanges = [ stronghold_range ];
      };
    networkmanager.enable = false;
    dhcpcd.enable = false;
    useNetworkd = true;
    useDHCP = false;
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
  systemd.network.wait-online.anyInterface = true;

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
    plasma5Packages.kalk
    plasma5Packages.kmail
    plasma5Packages.kdeplasma-addons

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

      displayManager.sddm =
        {
          enable = true;
          settings = {
            General = {
              DisplayServer = "wayland";
              GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
            };
            Wayland = {
              CompositorCommand = "kwin_wayland --no-lockscreen";
            };
          };
        };
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
      listenAddresses = [ "localhost:631" ];
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
                  grid = "1x1h(keep=all) | 6x1h | 7x1d";
                  regex = "^pointalpha_root_.*";
                }
              ];
              keep_receiver = [
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 7x1h | 15x1d | 6x30d | 1x365d";
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
        ];
      };
    };

    prometheus = {
      enable = true;
      port = 9001;
      retentionTime = "30d";
      globalConfig = {
        external_labels = { machine = "${config.networking.hostName}"; };
      };
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
              labels = { machine = "${config.networking.hostName}"; };
            }
          ];
        }
        {
          job_name = "zrepl";
          static_configs = [
            {
              targets = [ "localhost:${toString (builtins.head (helpers.zreplMonitoringPorts config.services.zrepl))}" ];
              labels = { machine = "${config.networking.hostName}"; };
            }
          ];
        }
      ];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9100;
        };
      };
    };
    avahi.enable = true;
    avahi.nssmdns = true;
    logmein-hamachi.enable = true;
  };
  security.rtkit.enable = true;
  security.pam.services.shawn.enableKwallet = true;
  security.auditd.enable = false;
  security.audit.enable = false;

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

  systemd.tmpfiles.rules = [ "d /media/nas 0750 shawn users -" ];

  programs.steam.enable = true;
  programs.dconf.enable = true;
  programs.adb.enable = true;
  programs.noisetorch.enable = true;
  programs.ssh.startAgent = true;

  environment = {
    variables.AMD_VULKAN_ICD = "RADV";
    variables.NIXOS_OZONE_WL = "1";
    etc."samba/credentials".source = config.age.secrets.samba_credentials.path;
    etc."zrepl/pointalpha.key".source = config.age.secrets.zrepl_pointalpha.path;
    etc."zrepl/pointalpha.crt".source = ../../public_certs/zrepl/pointalpha.crt;
    etc."zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
  };

  users.users.shawn = {
    extraGroups = [ "video" "audio" "libvirtd" "plugdev" "adbusers" "scanner" "lp" ];
  };

  # remove bloatware (NixOS HTML file)
  documentation.nixos.enable = false;

  system.stateVersion = "22.05";
}
