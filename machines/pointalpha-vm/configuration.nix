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
in {
  disabledModules = ["services/x11/display-managers/sddm.nix"];
  imports = [../../modules/nixos/overriden/sddm.nix ../../modules/nixos/steam-compat-tools.nix];

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

  networking = {
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

  fonts.fontconfig = {
    defaultFonts = {
      serif = ["Noto Serif"];
      sansSerif = ["Noto Sans"];
      monospace = ["Noto Sans Mono"];
    };
  };

  services = {
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
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';
    acpid.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
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
    pulseaudio.enable = false;
    opengl = {
      enable = true;
      driSupport = true;
      extraPackages = with pkgs; [libva];
    };
  };
  sound.enable = false;

  programs = {
    dconf.enable = true;
  };
  env.user-config.enable = true;

  environment = {
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
    plasma5.excludePackages = with pkgs.libsForQt5; [kwrited elisa ktnef];
  };

  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsHm9iUQIJVi/l1FTCIFwGxYhCOv23rkux6pMStL49N"];
  users.users.shawn = {
    extraGroups = ["video" "audio" "libvirtd" "adbusers" "scanner" "lp" "networkmanager" "nixbld"];
  };
}
