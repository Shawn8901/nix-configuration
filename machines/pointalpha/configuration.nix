{
  self,
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  fPkgs = self.packages.${system};
  hosts = self.nixosConfigurations;

  inherit (config.age) secrets;
  inherit (pkgs.hostPlatform) system;

  # https://github.com/NixOS/nixpkgs/pull/195521/files
  fontsPkg = pkgs: (pkgs.runCommand "share-fonts" {preferLocalBuild = true;} ''
    mkdir -p "$out/share/fonts"
    font_regexp='.*\.\(ttf\|ttc\|otf\|pcf\|pfa\|pfb\|bdf\)\(\.gz\)?'
    find ${toString config.fonts.fonts} -regex "$font_regexp" \
      -exec ln -sf -t "$out/share/fonts" '{}' \;
  '');
in {
  disabledModules = ["services/x11/display-managers/sddm.nix"];
  imports = [../../modules/nixos/overriden/sddm.nix ../../modules/nixos/steam-compat-tools.nix];

  age.secrets = {
    zrepl_pointalpha = {file = ../../secrets/zrepl_pointalpha.age;};
    shawn_samba_credentials = {
      file = ../../secrets/shawn_samba_credentials.age;
    };
    ela_samba_credentials = {file = ../../secrets/ela_samba_credentials.age;};
    prometheus_web_config = {
      file = ../../secrets/prometheus_internal_web_config.age;
      owner = "prometheus";
      group = "prometheus";
    };
    nix-netrc = lib.mkForce {
      file = ../../secrets/nix-netrc-rw.age;
      group = "nixbld";
      mode = "0440";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "deezer"
      "discord"
      "logmein-hamachi"
      "steam"
      "steam-run"
      "steam-original"
      "teamspeak-client"
      "teamviewer"
      "exodus"
      "vscode"
      "vscode-extension-MS-python-vscode-pylance"
      "tampermonkey"
      "betterttv"
      "Oracle_VM_VirtualBox_Extension_Pack"
    ];

  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          # Victoria 3
          ncurses
          # Universim
          (fontsPkg pkgs)
        ];
    };
  };

  networking = {
    firewall = let
      stronghold_range = {
        from = 2300;
        to = 2400;
      };
      stronghold_tcp = 47624;
      zreplServePorts = inputs.zrepl.servePorts config.services.zrepl;
    in {
      allowedUDPPortRanges = [stronghold_range];
      allowedTCPPorts = [config.services.prometheus.port stronghold_tcp] ++ zreplServePorts;
      allowedTCPPortRanges = [stronghold_range];
    };
    networkmanager = {
      enable = true;
      plugins = lib.mkForce [];
    };
    nftables.enable = true;
    hosts = {
      "192.168.11.31" = lib.attrNames hosts.tank.config.services.nginx.virtualHosts;
      "134.255.226.114" = ["pointjig"];
      "2a05:bec0:1:16::114" = ["pointjig"];
      "78.128.127.235" = ["shelter"];
      "2a01:8740:1:e4::2cd3" = ["shelter"];
      "132.145.224.161" = ["hydra.pointjig.de"];
    };
    dhcpcd.enable = false;
    useNetworkd = false;
    useDHCP = false;
  };
  services.resolved.enable = false;
  systemd.network.wait-online.anyInterface = true;

  environment.systemPackages = with pkgs; [
    cifs-utils
    plasma5Packages.skanlite
    plasma5Packages.ark
    plasma5Packages.kate
    plasma5Packages.kalk
    plasma5Packages.kmail
    plasma5Packages.kdeplasma-addons
    zenmonitor
    nixpkgs-review
  ];

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      dejavu_fonts
      font-awesome
      freefont_ttf
      liberation_ttf
      noto-fonts
      noto-fonts-emoji
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Serif"];
        sansSerif = ["Noto Sans"];
        monospace = ["Noto Sans Mono"];
      };
    };
  };

  services = {
    udev = {
      packages = [pkgs.libmtp.out];
      extraRules = ''
      '';
    };
    xserver = {
      enable = true;
      layout = "de";
      videoDrivers = ["amdgpu"];
      displayManager.sddm = {
        enable = true;
        autoNumlock = true;
        #package = self.packages.${system}.sddm-git;
        #         settings = {
        #           General = {
        #             InputMethod = "";
        # #            DisplayServer = "wayland";
        #             GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
        #           };
        #           Wayland = {
        #             CompositorCommand = "/run/wrappers/bin/kwin_wayland --no-lockscreen";
        #           };
        #         };
      };
      displayManager.defaultSession = "plasmawayland";
      desktopManager.plasma5 = {
        enable = true;
        phononBackend = "vlc";
        excludePackages = with pkgs.libsForQt5; [kwrited elisa ktnef];
      };
      desktopManager.xterm.enable = false;
      excludePackages = [pkgs.xterm];
    };
    openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
    };
    zfs = {
      trim.enable = true;
      autoScrub = {
        enable = true;
        pools = ["rpool"];
      };
    };

    pipewire = let
      rate = 48000;
      quantum = 64;
      minQuantum = 32;
      maxQuantum = 8192;
      qr = "${toString quantum}/${toString rate}";
      rtLimitSoft = 200000;
      rtLimitHard = 300000;
    in {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      media-session.enable = false;
      wireplumber.enable = true;
      config.pipewire = {
        "context.properties" = {
          "link.max-buffers" = 16;
          "log.level" = 2;
          "default.clock.rate" = rate;
          "default.clock.quantum" = quantum;
          "default.clock.min-quantum" = minQuantum;
          "default.clock.max-quantum" = maxQuantum;
          "core.daemon" = true;
          "core.name" = "pipewire-0";
        };
        "context.modules" = [
          {
            name = "libpipewire-module-rtkit";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = rtLimitSoft;
              "rt.time.hard" = rtLimitHard;
            };
            flags = ["ifexists" "nofail"];
          }
          {name = "libpipewire-module-protocol-native";}
          {name = "libpipewire-module-profiler";}
          {name = "libpipewire-module-metadata";}
          {name = "libpipewire-module-spa-device-factory";}
          {name = "libpipewire-module-spa-node-factory";}
          {name = "libpipewire-module-client-node";}
          {name = "libpipewire-module-client-device";}
          {
            name = "libpipewire-module-portal";
            flags = ["ifexists" "nofail"];
          }
          {
            name = "libpipewire-module-access";
            args = {};
          }
          {name = "libpipewire-module-adapter";}
          {name = "libpipewire-module-link-factory";}
          {name = "libpipewire-module-session-manager";}
        ];
      };
      config.pipewire-pulse = {
        "context.properties" = {
          "log.level" = 2;
        };
        "context.modules" = [
          {
            name = "libpipewire-module-rtkit";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = rtLimitSoft;
              "rt.time.hard" = rtLimitHard;
            };
            flags = ["ifexists" "nofail"];
          }
          {name = "libpipewire-module-protocol-native";}
          {name = "libpipewire-module-client-node";}
          {name = "libpipewire-module-adapter";}
          {name = "libpipewire-module-metadata";}
          {
            name = "libpipewire-module-protocol-pulse";
            args = {
              "pulse.min.req" = qr;
              "pulse.default.req" = qr;
              "pulse.max.req" = qr;
              "pulse.min.quantum" = qr;
              "pulse.max.quantum" = qr;
              "server.address" = ["unix:native"];
            };
          }
        ];
        "stream.properties" = {
          "node.latency" = qr;
          "resample.quality" = 1;
        };
      };
    };
    printing = {
      enable = true;
      listenAddresses = ["localhost:631"];
      drivers = [pkgs.epson-escpr2];
    };
    zrepl = {
      enable = true;
      package = pkgs.zrepl;
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
            name = "pointalpha_safe";
            type = "source";
            filesystems = {"rpool/safe<" = true;};
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            send = {
              encrypted = false;
              compressed = true;
            };
            serve = {
              type = "tls";
              listen = ":8888";
              ca = "/etc/zrepl/tank.crt";
              cert = "/etc/zrepl/pointalpha.crt";
              key = "/etc/zrepl/pointalpha.key";
              client_cns = ["tank"];
            };
          }
        ];
      };
    };

    prometheus = let
      labels = {machine = "${config.networking.hostName}";};
      nodePort = config.services.prometheus.exporters.node.port;
      zfsPort = toString config.services.prometheus.exporters.zfs.port;
      smartctlPort = config.services.prometheus.exporters.smartctl.port;
      zreplPort =
        builtins.head
        (
          inputs.zrepl.monitoringPorts
          config.services.zrepl
        );
    in {
      enable = true;
      port = 9001;
      retentionTime = "90d";
      globalConfig = {
        external_labels = labels;
      };
      webConfigFile = secrets.prometheus_web_config.path;
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["localhost:${toString nodePort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "zfs";
          static_configs = [
            {
              targets = ["localhost:${zfsPort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "smartctl";
          static_configs = [
            {
              targets = ["localhost:${toString smartctlPort}"];
              inherit labels;
            }
          ];
        }
        {
          job_name = "zrepl";
          static_configs = [
            {
              targets = ["localhost:${toString zreplPort}"];
              inherit labels;
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
        smartctl = {
          enable = true;
          listenAddress = "localhost";
          port = 9102;
          devices = ["/dev/sda"];
          maxInterval = "5m";
        };
        zfs = {
          enable = true;
          listenAddress = "localhost";
          port = 9134;
        };
      };
    };
    avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';
    acpid.enable = true;
    smartd.enable = true;
    teamviewer.enable = true;
  };
  security = {
    rtkit.enable = true;
    auditd.enable = false;
    audit.enable = false;
    pam.services.shawn.enableKwallet = true;
  };
  hardware = {
    bluetooth.enable = true;
    sane.enable = true;
    keyboard.zsa.enable = true;
    pulseaudio.enable = false;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [libva];
    };
  };
  sound.enable = false;
  systemd.tmpfiles.rules = ["d /media/nas 0750 shawn users -"];

  programs = {
    steam = {
      enable = true;
      extraCompatPackages = [fPkgs.proton-ge-custom];
    };
    dconf.enable = true;
    noisetorch.enable = true;
    noisetorch.package = fPkgs.noisetorch;
    ssh.startAgent = true;
    iotop.enable = true;
    haguichi.enable = false;
    ausweisapp = {
      enable = true;
      openFirewall = true;
    };
    partition-manager.enable = true;
  };
  env.user-config.enable = true;

  environment = {
    etc = {
      "samba/credentials_shawn".source = secrets.shawn_samba_credentials.path;
      "samba/credentials_ela".source = secrets.ela_samba_credentials.path;
      "zrepl/pointalpha.key".source = secrets.zrepl_pointalpha.path;
      "zrepl/pointalpha.crt".source = ../../public_certs/zrepl/pointalpha.crt;
      "zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
    };
    variables = {
      AMD_VULKAN_ICD = "RADV";
      DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1 = "1";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
      mesa_glthread = "true";
      WINEFSYNC = "1";
      WINEDEBUG = "-all";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      NIXOS_OZONE_WL = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };
  };
  nix.settings.netrc-file = lib.mkForce secrets.nix-netrc.path;

  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N"];
  users.users.shawn = {
    extraGroups = ["video" "audio" "libvirtd" "adbusers" "scanner" "lp" "networkmanager" "nixbld"];
  };
}
