{ self, pkgs, lib, config, inputs, ... }:

let
  fPkgs = self.packages.${system};
  hosts = self.nixosConfigurations;
  system = pkgs.hostPlatform.system;
  secrets = config.age.secrets;
in
{
  disabledModules = [ "services/x11/display-managers/sddm.nix" "programs/steam.nix" "services/monitoring/prometheus/default.nix" ];
  imports = [ ../../modules/nixos/overriden/sddm.nix ../../modules/nixos/overriden/steam.nix ../../modules/nixos/overriden/prometheus.nix ];

  age.secrets = {
    zrepl_pointalpha = { file = ../../secrets/zrepl_pointalpha.age; };
    shawn_samba_credentials = {
      file = ../../secrets/shawn_samba_credentials.age;
    };
    ela_samba_credentials = { file = ../../secrets/ela_samba_credentials.age; };
    prometheus_web_config = {
      file = ../../secrets/web_config_pointalpha_prometheus.age;
      owner = "prometheus";
      group = "prometheus";
    };
  };

  nixpkgs.overlays = [ inputs.nur.outputs.overlay ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "discord"
      "logmein-hamachi"
      "steam"
      "steam-run"
      "steam-original"
      "teamspeak-client"
      "teamviewer"
      "vscode"
      "vscode-extension-MS-python-vscode-pylance"
      "tampermonkey"
      "betterttv"
      "Oracle_VM_VirtualBox_Extension_Pack"
    ];

  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        ncurses
        fontconfig
      ];
    };
    # Disable the tests for this package, as their test files includes non utf-8 chars which we reject being created due utf8only on zfs
    # jpylyzer = pkgs.jpylyzer.overrideAttrs (oldAttrs: {
    #   preCheck = '''';
    #   doChecks = false;
    # });
  };
  services.flatpak.enable = true;

  networking = {
    firewall =
      let
        stronghold_range = {
          from = 2300;
          to = 2400;
        };
        stronghold_tcp = 47624;
        zreplServePorts = inputs.zrepl.servePorts config.services.zrepl;
      in
      {
        allowedUDPPortRanges = [ stronghold_range ];
        allowedTCPPorts = [ config.services.prometheus.port stronghold_tcp ] ++ zreplServePorts;
        allowedTCPPortRanges = [ stronghold_range ];
      };
    networkmanager.enable = true;
    hosts = {
      "192.168.11.31" = lib.attrNames hosts.tank.config.services.nginx.virtualHosts;
      "134.255.226.114" = [ "pointjig" ];
      "2a05:bec0:1:16::114" = [ "pointjig" ];
      "78.128.127.235" = [ "shelter" ];
      "2a01:8740:1:e4::2cd3" = [ "shelter" ];
    };
    dhcpcd.enable = false;
    useNetworkd = false;
    useDHCP = false;
  };
  services.resolved.enable = false;
  systemd.network = {
    enable = false;
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

    qt5.qtwayland
    plasma5Packages.skanlite
    plasma5Packages.ark
    plasma5Packages.kate
    plasma5Packages.kalk
    plasma5Packages.kmail
    plasma5Packages.kdeplasma-addons

    python39
    sysstat
    nixpkgs-review
  ];

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      dejavu_fonts
      font-awesome
      freefont_ttf
      liberation_ttf
      roboto
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      powerline-fonts
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Noto Sans Mono" ];
      };
    };
  };

  services = {
    udev = {
      packages = [ pkgs.libmtp.out ];
      extraRules = ''
      '';
    };
    xserver = {
      enable = true;
      layout = "de";
      videoDrivers = [ "amdgpu" ];
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
      excludePackages = [ pkgs.xterm ];
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
    zfs.trim.enable = true;
    zfs.autoScrub.enable = true;
    zfs.autoScrub.pools = [ "rpool" ];

    pipewire =
      let
        rate = 48000;
        quantum = 64;
        minQuantum = 32;
        maxQuantum = 8192;
        qr = "${toString quantum}/${toString rate}";
        rtLimitSoft = 200000;
        rtLimitHard = 300000;
      in
      {
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
              flags = [ "ifexists" "nofail" ];
            }
            { name = "libpipewire-module-protocol-native"; }
            { name = "libpipewire-module-profiler"; }
            { name = "libpipewire-module-metadata"; }
            { name = "libpipewire-module-spa-device-factory"; }
            { name = "libpipewire-module-spa-node-factory"; }
            { name = "libpipewire-module-client-node"; }
            { name = "libpipewire-module-client-device"; }
            {
              name = "libpipewire-module-portal";
              flags = [ "ifexists" "nofail" ];
            }
            {
              name = "libpipewire-module-access";
              args = { };
            }
            { name = "libpipewire-module-adapter"; }
            { name = "libpipewire-module-link-factory"; }
            { name = "libpipewire-module-session-manager"; }
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
              flags = [ "ifexists" "nofail" ];
            }
            { name = "libpipewire-module-protocol-native"; }
            { name = "libpipewire-module-client-node"; }
            { name = "libpipewire-module-adapter"; }
            { name = "libpipewire-module-metadata"; }
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                "pulse.min.req" = qr;
                "pulse.default.req" = qr;
                "pulse.max.req" = qr;
                "pulse.min.quantum" = qr;
                "pulse.max.quantum" = qr;
                "server.address" = [ "unix:native" ];
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
      listenAddresses = [ "localhost:631" ];
      drivers = [ pkgs.epson-escpr2 ];
    };
    zrepl = {
      enable = true;
      package = pkgs.zrepl;
      settings = {
        global = {
          monitoring = [{
            type = "prometheus";
            listen = ":9811";
            listen_freebind = true;
          }];
        };
        jobs = [{
          name = "pointalpha_safe";
          type = "source";
          filesystems = { "rpool/safe<" = true; };
          snapshotting = {
            type = "periodic";
            interval = "1h";
            prefix = "zrepl_";
          };
          send = { encrypted = false; compressed = true; };
          serve = {
            type = "tls";
            listen = ":8888";
            ca = "/etc/zrepl/tank.crt";
            cert = "/etc/zrepl/pointalpha.crt";
            key = "/etc/zrepl/pointalpha.key";
            client_cns = [ "tank" ];
          };
        }];
      };
    };

    prometheus =
      let
        labels = { machine = "${config.networking.hostName}"; };
        nodePort = config.services.prometheus.exporters.node.port;
        zreplPort = (builtins.head
          (
            inputs.zrepl.monitoringPorts
              config.services.zrepl
          ));
      in
      {
        enable = true;
        port = 9001;
        retentionTime = "30d";
        globalConfig = {
          external_labels = labels;
        };
        web_config_file = secrets.prometheus_web_config.path;
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [{ targets = [ "localhost:${toString nodePort}" ]; inherit labels; }];
          }
          {
            job_name = "zrepl";
            static_configs = [{ targets = [ "localhost:${toString zreplPort}" ]; inherit labels; }];
          }
        ];
        exporters = {
          node = {
            enable = true;
            listenAddress = "localhost";
            port = 9101;
            enabledCollectors = [ "systemd" ];
          };
        };
      };
    avahi.enable = true;
    avahi.nssmdns = true;

    journald.extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=100M
    '';
    acpid.enable = true;
    teamviewer.enable = false;
  };
  security.rtkit.enable = true;
  security.auditd.enable = false;
  security.audit.enable = false;

  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = true;
  hardware.sane.enable = true;
  hardware.keyboard.zsa.enable = true;
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
  virtualisation.virtualbox.host.enable = false;
  virtualisation.virtualbox.host.enableExtensionPack = false;

  systemd.tmpfiles.rules = [ "d /media/nas 0750 shawn users -" ];

  programs = {
    steam = {
      enable = true;
      extraCompatPackages = [ fPkgs.proton-ge-custom ];
    };
    chromium.enable = true;
    dconf.enable = true;
    adb.enable = false;
    noisetorch.enable = true;
    noisetorch.package = fPkgs.noisetorch;
    ssh.startAgent = true;
    iotop.enable = true;
    haguichi.enable = false;
    ausweisapp = {
      enable = true;
      openFirewall = true;
    };
  };
  env.user-config.enable = true;

  environment = {
    etc."samba/credentials_shawn".source = secrets.shawn_samba_credentials.path;
    etc."samba/credentials_ela".source = secrets.ela_samba_credentials.path;
    etc."zrepl/pointalpha.key".source = secrets.zrepl_pointalpha.path;
    etc."zrepl/pointalpha.crt".source = ../../public_certs/zrepl/pointalpha.crt;
    etc."zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;

    variables.AMD_VULKAN_ICD = "RADV";
    variables.MOZ_ENABLE_WAYLAND = "1";
    variables.MOZ_DISABLE_RDD_SANDBOX = "1";
    variables.NIXOS_OZONE_WL = "1";
    variables.SDL_VIDEODRIVER = "wayland";
    variables.QT_QPA_PLATFORM = "wayland";
    variables.QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    variables._JAVA_AWT_WM_NONREPARENTING = "1";
  };

  security.pam.services.shawn.enableKwallet = true;

  users.groups.plugdev = { };
  users.users.shawn = {
    extraGroups = [ "video" "audio" "libvirtd" "plugdev" "adbusers" "scanner" "lp" "networkmanager" "nixbld" ];
  };
}
