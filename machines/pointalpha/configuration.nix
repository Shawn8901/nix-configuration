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
  unoptimized = inputs.nixpkgs.legacyPackages.${system};

  inherit (config.sops) secrets;
  inherit (pkgs.hostPlatform) system;
in {
  disabledModules = ["services/x11/display-managers/sddm.nix"];
  imports = [../../modules/nixos/overriden/sddm.nix];

  sops.secrets = {
    zrepl = {};
    samba = {};
    samba-ela = {};
    prometheus-web-config = {
      owner = "prometheus";
      group = "prometheus";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "deezer"
      "discord"
      "steam"
      "steam-run"
      "steam-original"
      "teamspeak-client"
      "teamviewer"
      "exodus"
      "vscode"
      "vscode-extension-MS-python-vscode-pylance"
      "vscode-extension-ms-vscode-cpptools"
      "tampermonkey"
      "betterttv"
    ];

  # Override some packages to unoptimized, that do not compile with x86_64-v3 stdenv
  nixpkgs.config.packageOverrides = pkgs: {
    inherit (unoptimized) openexr_3;
    haskellPackages = pkgs.haskellPackages.override {
      overrides = haskellPackagesNew: haskellPackagesOld: {
        inherit (unoptimized.haskellPackages) cryptonite hermes-json hermes-json_0_2_0_1;
      };
    };

    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          # Victoria 3
          ncurses
          # Fix fonts for Unity games
          # https://github.com/NixOS/nixpkgs/pull/195521/files
          (pkgs.runCommand "share-fonts" {preferLocalBuild = true;} ''
            mkdir -p "$out/share/fonts"
            font_regexp='.*\.\(ttf\|ttc\|otf\|pcf\|pfa\|pfb\|bdf\)\(\.gz\)?'
            find ${toString [pkgs.liberation_ttf pkgs.dejavu_fonts]} -regex "$font_regexp" \
              -exec ln -sf -t "$out/share/fonts" '{}' \;
          '')
        ];
    };

    udisks2 = pkgs.udisks2.override {
      btrfs-progs = null;
      nilfs-utils = null;
      xfsprogs = null;
      f2fs-tools = null;
    };

    partition-manager = pkgs.partition-manager.override {
      btrfs-progs = null;
      e2fsprogs = null;
      f2fs-tools = null;
      hfsprogs = null;
      jfsutils = null;
      nilfs-utils = null;
      reiser4progs = null;
      reiserfsprogs = null;
      udftools = null;
      xfsprogs = null;
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
    };
    dhcpcd.enable = false;
    useNetworkd = false;
    useDHCP = false;
  };
  services.resolved.enable = false;
  systemd.network.wait-online.anyInterface = true;

  environment.systemPackages = with pkgs;
    [
      cifs-utils
      plasma5Packages.skanlite
      plasma5Packages.ark
      plasma5Packages.kate
      plasma5Packages.kalk
      plasma5Packages.kmail
      plasma5Packages.kdeplasma-addons
      zenmonitor
      nixpkgs-review
    ]
    ++ [inputs.nh.packages.${system}.default];

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
        package = self.packages.${system}.sddm-git;
        settings = {
          General = {
            InputMethod = "";
            #            DisplayServer = "wayland";
            GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
          };
          Wayland = {
            CompositorCommand = "/run/wrappers/bin/kwin_wayland --no-lockscreen";
          };
        };
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
      webConfigFile = secrets.prometheus-web-config.path;
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
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      wireplumber.enable = true;
    };
  };
  security = {
    rtkit.enable = true;
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
    haguichi.enable = false;
    ausweisapp = {
      enable = true;
      openFirewall = true;
    };
    partition-manager.enable = true;
  };
  shawn8901.user-config.enable = true;

  virtualisation = {
    libvirtd = {
      enable = false;
      onBoot = "start";
      qemu.package = pkgs.qemu_kvm;
    };
  };

  nix.settings = {
    keep-outputs = true;
    keep-derivations = true;
  };
  environment = {
    etc = {
      "samba/credentials_ela".source = secrets.samba-ela.path;
      "samba/credentials_shawn".source = secrets.samba.path;
      "zrepl/pointalpha.key".source = secrets.zrepl.path;
      "zrepl/pointalpha.crt".source = ../../files/public_certs/zrepl/pointalpha.crt;
      "zrepl/tank.crt".source = ../../files/public_certs/zrepl/tank.crt;
    };
    sessionVariables = {
      FLAKE = "/home/shawn/dev/nix-configuration";
      AMD_VULKAN_ICD = "RADV";
      WINEFSYNC = "1";
      WINEDEBUG = "-all";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      NIXOS_OZONE_WL = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };
    plasma5.excludePackages = with pkgs.plasma5Packages; [elisa khelpcenter];
  };
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N"];
  users.users.shawn.extraGroups = ["video" "audio" "libvirtd" "adbusers" "scanner" "lp" "networkmanager" "nixbld"];
}
