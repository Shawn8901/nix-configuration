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
in {
  disabledModules = ["services/x11/display-managers/sddm.nix"];
  imports = [../../modules/nixos/overriden/sddm.nix];

  age.secrets = {
    shawn_samba_credentials = {
      file = ../../secrets/shawn_samba_credentials.age;
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "deezer"
      "discord"
      "exodus"
      "vscode"
      "vscode-extension-MS-python-vscode-pylance"
      "tampermonkey"
      "betterttv"
    ];

  nixpkgs.config.packageOverrides = pkgs: {
  };

  networking = {
    firewall = {
      allowedUDPPortRanges = [];
      allowedTCPPorts = [];
      allowedTCPPortRanges = [];
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
        jobs = [];
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
    dconf.enable = true;
    ssh.startAgent = true;
    iotop.enable = true;
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
    };
    variables = {
      AMD_VULKAN_ICD = "RADV";
      DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1 = "1";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
      mesa_glthread = "true";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      MOZ_USE_XINPUT2 = "1";
      NIXOS_OZONE_WL = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };
  };
  users.users.shawn = {
    extraGroups = ["video" "audio" "scanner" "lp" "networkmanager" "nixbld"];
  };
}
