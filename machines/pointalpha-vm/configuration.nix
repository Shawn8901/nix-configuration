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

  # Override some packages to unoptimized, that do not compile with x86_64-v3
  nixpkgs.config.packageOverrides = pkgs: {
    inherit (unoptimized) openexr_3;
    haskellPackages = pkgs.haskellPackages.override {
      overrides = haskellPackagesNew: haskellPackagesOld: {
        inherit (unoptimized.haskellPackages) cryptonite hermes-json hermes-json_0_2_0_1;
      };
    };
  };

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
            DisplayServer = "wayland";
            GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
          };
          Wayland = {
            CompositorCommand = "kwin_wayland --no-global-shortcuts --no-lockscreen --inputmethod maliit-keyboard --locale1";
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
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/etc/ssh/ssh_host_rsa_key";
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

  environment = {
    variables = {
      AMD_VULKAN_ICD = "RADV";
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

  users.users.shawn = {
    password = "1234";
    isNormalUser = true;
    extraGroups = ["video" "audio" "wheel" "scanner" "lp" "networkmanager"];
  };
}
