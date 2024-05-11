{
  self',
  pkgs,
  lib,
  config,
  inputs',
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    optionalAttrs
    versionOlder
    ;

  cfg = config.shawn8901.desktop;
  fPkgs = self'.packages;
in
{

  options = {
    shawn8901.desktop = {
      enable = mkEnableOption "my desktop settings for nixos";
    };
  };
  config = mkIf cfg.enable {

    documentation.man = {
      enable = lib.mkDefault true;
      generateCaches = lib.mkDefault true;
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

    services =
      {
        acpid.enable = true;
        avahi = lib.mkMerge [
          {
            enable = true;
            openFirewall = true;
          }
          (optionalAttrs (versionOlder config.system.nixos.release "24.05") { nssmdns = true; })
          (optionalAttrs (!versionOlder config.system.nixos.release "24.05") { nssmdns4 = true; })
        ];
        pipewire = {
          enable = true;
          pulse.enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          wireplumber.enable = true;
        };
      }
      // (optionalAttrs (!versionOlder config.system.nixos.release "24.05") {
        desktopManager.plasma6.enable = true;
        displayManager.sddm = {
          enable = lib.mkDefault true;
          autoNumlock = true;
          wayland = {
            enable = true;
            compositor = "kwin";
          };
        };
      });

    security = {
      rtkit.enable = true;
      auditd.enable = false;
      audit.enable = false;
    };

    systemd.defaultUnit = "graphical.target";

    hardware = {
      bluetooth = {
        enable = true;
        package = pkgs.bluez5-experimental;
        settings = {
          General = {
            Experimental = true;
          };
        };
        input = {
          General = {
            ClassicBondedOnly = false;
          };
        };
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
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    environment = lib.mkMerge [
      {
        sessionVariables = {
          AMD_VULKAN_ICD = "RADV";
          MOZ_ENABLE_WAYLAND = "1";
          MOZ_DISABLE_RDD_SANDBOX = "1";
          NIXOS_OZONE_WL = "1";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          _JAVA_AWT_WM_NONREPARENTING = "1";
          GTK_USE_PORTAL = "1";
        };
        systemPackages =
          with pkgs;
          lib.mkMerge [
            (lib.optionals (config.services ? desktopManager && config.services.desktopManager.plasma6.enable) (
              with pkgs.kdePackages;
              [
                ark
                print-manager
                kate
                skanlite
                kalk
              ]
            ))
            [
              git
              inputs'.nh.packages.default
              (pkgs.btop.override { rocmSupport = true; })
            ]
          ];
      }
      (lib.optionalAttrs
        (config.services ? desktopManager && config.services.desktopManager.plasma6.enable)
        {
          plasma6.excludePackages = with pkgs.kdePackages; [
            elisa
            khelpcenter
            kate
            gwenview
          ];
        }
      )
    ];

    programs = lib.mkMerge [
      {
        dconf.enable = true;
        ssh.startAgent = true;
        steam = {
          enable = true;
          package = pkgs.steam-small.override {
            extraEnv = {
              inherit (config.environment.sessionVariables) AMD_VULKAN_ICD;
            };
            extraLibraries = p: [
              # Fix Unity Fonts
              (pkgs.runCommand "share-fonts" { preferLocalBuild = true; } ''
                mkdir -p "$out/share/fonts"
                font_regexp='.*\.\(ttf\|ttc\|otf\|pcf\|pfa\|pfb\|bdf\)\(\.gz\)?'
                find ${
                  toString [
                    pkgs.liberation_ttf
                    pkgs.dejavu_fonts
                  ]
                } -regex "$font_regexp" \
                  -exec ln -sf -t "$out/share/fonts" '{}' \;
              '')
              p.getent
            ];
          };
        };
        haguichi.enable = false;
      }
      (lib.optionalAttrs (config.programs ? kde-pim) {
        kde-pim = {
          enable = true;
          kmail = true;
        };
      })
    ];
  };
}
