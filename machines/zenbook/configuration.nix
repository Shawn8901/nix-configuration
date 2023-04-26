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

  inherit (config.sops) secrets;
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
  imports = [../../modules/nixos/overriden/sddm.nix];

  sops.secrets = {
    zrepl = {restartUnits = ["zrepl.service"];};
    samba = {sopsFile = ./../../files/secrets-desktop.yaml;};
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "deezer"
      "discord"
      "exodus"
      "steam"
      "steam-run"
      "steam-original"
      "vscode"
      "vscode-extension-MS-python-vscode-pylance"
      "tampermonkey"
      "betterttv"
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
    firewall = {
      allowedUDPPortRanges = [];
      allowedTCPPorts = [];
      allowedTCPPortRanges = [];
      logReversePathDrops = true;
      checkReversePath = false;
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

  fonts.fontconfig = {
    defaultFonts = {
      serif = ["Noto Serif"];
      sansSerif = ["Noto Sans"];
      monospace = ["Noto Sans Mono"];
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
    printing = {
      enable = true;
      listenAddresses = ["localhost:631"];
      drivers = [pkgs.epson-escpr2];
    };
    zrepl = {
      enable = true;
      package = pkgs.zrepl;
      settings = {
        jobs = [
          {
            name = "zenbook";
            type = "push";
            filesystems = {"rpool/safe<" = true;};
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            connect = let
              zreplPort = builtins.head (inputs.zrepl.servePorts hosts.tank.config.services.zrepl);
            in {
              type = "tls";
              address = "tank.fritz.box:${toString zreplPort}";
              ca = "/etc/zrepl/tank.crt";
              cert = "/etc/zrepl/zenbook.crt";
              key = "/etc/zrepl/zenbook.key";
              server_cn = "tank";
            };
            send = {
              encrypted = true;
              compressed = true;
            };
            pruning = {
              keep_sender = [
                {type = "not_replicated";}
                {
                  type = "grid";
                  grid = "1x3h(keep=all) | 2x6h | 30x1d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
              keep_receiver = [
                {
                  type = "grid";
                  grid = "1x3h(keep=all) | 2x6h | 30x1d | 6x30d | 1x365d";
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
        ];
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
    upower.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
    };
  };
  security = {
    auditd.enable = false;
    audit.enable = false;
    pam.services.sddm.enableKwallet = true;
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
      extraPackages32 = with pkgs.pkgsi686Linux; [libva];
    };
    asus-touchpad-numpad = {
      enable = true;
      package = fPkgs.asus-touchpad-numpad-driver;
      model = "ux433fa";
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
    ssh.startAgent = true;
    iotop.enable = true;
    ausweisapp = {
      enable = true;
      openFirewall = true;
    };
  };
  shawn8901.user-config.enable = true;

  environment = {
    etc = {
      "zrepl/zenbook.key".source = secrets.zrepl.path;
      "samba/credentials_shawn".source = secrets.samba.path;
      "zrepl/zenbook.crt".source = ../../public_certs/zrepl/zenbook.crt;
      "zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
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
    plasma5.excludePackages = with pkgs.libsForQt5; [kwrited elisa ktnef];
  };
  users.users.shawn = {
    extraGroups = ["video" "audio" "scanner" "lp" "networkmanager" "nixbld"];
  };
}
