{
  pkgs,
  lib,
  config,
  ...
}: {
  fonts = lib.mkMerge [
    {
      fontconfig = {
        hinting.autohint = true;
        cache32Bit = true;
        subpixel.lcdfilter = "light";
        defaultFonts = {
          emoji = ["Noto Color Emoji"];
          serif = ["Noto Serif"];
          sansSerif = ["Noto Sans"];
          monospace = ["Noto Sans Mono"];
        };
      };
    }
    (lib.optionalAttrs (builtins.hasAttr "packages" config.fonts) {
      enableDefaultPackages = lib.mkDefault true;
      packages = [pkgs.noto-fonts];
    })
    # Remove with 23.11
    (lib.optionalAttrs (!builtins.hasAttr "packages" config.fonts) {
      enableDefaultFonts = lib.mkDefault true;
      fonts = [pkgs.noto-fonts];
    })
  ];

  services = {
    acpid.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
    smartd.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      wireplumber.enable = true;
    };
    xserver = {
      enable = lib.mkDefault true;
      layout = "de";
      videoDrivers = ["amdgpu"];
      displayManager.sddm = {
        enable = lib.mkDefault true;
        autoNumlock = true;
        #enableKwinWayland = false;
      };
      displayManager.defaultSession = "plasmawayland";
      desktopManager.plasma5 = {
        enable = true;
        phononBackend = "vlc";
      };
      desktopManager.xterm.enable = false;
      excludePackages = [pkgs.xterm];
    };
  };

  security = {
    rtkit.enable = true;
    auditd.enable = false;
    audit.enable = false;
  };

  programs = {
    dconf.enable = true;
  };

  hardware = {
    bluetooth.enable = true;
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

  environment.systemPackages = with pkgs; [
    plasma5Packages.skanlite
    plasma5Packages.ark
    plasma5Packages.kate
    plasma5Packages.kalk
    plasma5Packages.kmail
    plasma5Packages.kdeplasma-addons
  ];

  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  environment = {
    sessionVariables = {
      AMD_VULKAN_ICD = "RADV";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      NIXOS_OZONE_WL = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      GTK_USE_PORTAL = "1";
    };
    plasma5.excludePackages = with pkgs.plasma5Packages; [elisa khelpcenter];
  };
}
