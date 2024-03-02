{ self', pkgs, lib, config, inputs', ... }:
let
  inherit (lib) mkEnableOption mkIf optionalAttrs versionOlder;

  cfg = config.shawn8901.desktop;
  fPkgs = self'.packages;

in {

  options = {
    shawn8901.desktop = {
      enable = mkEnableOption "my desktop settings for nixos";
    };
  };
  config = mkIf cfg.enable {

    documentation = {
      doc.enable = false;
      nixos.enable = false;
      info.enable = false;
      man = {
        enable = lib.mkDefault true;
        generateCaches = lib.mkDefault true;
      };
    };

    fonts = {
      fontconfig = {
        hinting.autohint = true;
        cache32Bit = true;
        subpixel.lcdfilter = "light";
        defaultFonts = {
          emoji = [ "Noto Color Emoji" ];
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
          monospace = [ "Noto Sans Mono" ];
        };
      };
      enableDefaultPackages = lib.mkDefault true;
      packages = [ pkgs.noto-fonts ];
    };

    services = {
      acpid.enable = true;
      avahi = lib.mkMerge [
        {
          enable = true;
          openFirewall = true;
        }
        (optionalAttrs (versionOlder config.system.nixos.release "24.05") {
          nssmdns = true;
        })
        (optionalAttrs (!versionOlder config.system.nixos.release "24.05") {

          nssmdns4 = true;
        })
      ];
      smartd.enable = true;
      pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        wireplumber.enable = true;
      };
      xserver = lib.mkMerge [
        {
          enable = lib.mkDefault true;

          videoDrivers = [ "amdgpu" ];
          displayManager.sddm = {
            enable = lib.mkDefault true;
            autoNumlock = true;
            wayland.enable = true;
          };
          displayManager.defaultSession = "plasmawayland";
          desktopManager.plasma5 = {
            enable = true;
            phononBackend = "vlc";
          };
          desktopManager.xterm.enable = false;
          excludePackages = [ pkgs.xterm ];
        }
        (optionalAttrs (versionOlder config.system.nixos.release "24.05") {
          layout = "de";
        })
        (optionalAttrs (!versionOlder config.system.nixos.release "24.05") {
          xkb.layout = "de";
        })
      ];
    };

    security = {
      rtkit.enable = true;
      auditd.enable = false;
      audit.enable = false;
    };

    programs = { dconf.enable = true; };

    hardware = {
      bluetooth = {
        enable = true;
        settings = { General = { Experimental = true; }; };
      };
      pulseaudio.enable = false;
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [ libva ];
        extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
      };
    };
    sound.enable = false;

    environment.systemPackages = with pkgs;
      [
        plasma5Packages.skanlite
        plasma5Packages.ark
        plasma5Packages.kate
        plasma5Packages.kalk
        plasma5Packages.kmail
        plasma5Packages.kdeplasma-addons
        git
      ] ++ [ inputs'.nh.packages.default ];

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

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
      plasma5.excludePackages = with pkgs.plasma5Packages; [
        elisa
        khelpcenter
      ];
    };

    programs = {
      steam = {
        enable = true;
        package = pkgs.steam-small.override {
          extraEnv = {
            AMD_VULKAN_ICD = config.environment.sessionVariables.AMD_VULKAN_ICD;
          };
          extraLibraries = p: [
            # Fix Unity Fonts
            (pkgs.runCommand "share-fonts" { preferLocalBuild = true; } ''
              mkdir -p "$out/share/fonts"
              font_regexp='.*\.\(ttf\|ttc\|otf\|pcf\|pfa\|pfb\|bdf\)\(\.gz\)?'
              find ${
                toString [ pkgs.liberation_ttf pkgs.dejavu_fonts ]
              } -regex "$font_regexp" \
                -exec ln -sf -t "$out/share/fonts" '{}' \;
            '')
            p.getent
          ];
        };
      };
      haguichi.enable = false;
    };
  };
}
