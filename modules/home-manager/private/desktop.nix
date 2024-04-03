{
  self',
  config,
  lib,
  pkgs,
  inputs,
  inputs',
  ...
}:
let
  inherit (lib) mkEnableOption mkIf getExe;
  inherit (inputs.firefox-addons.lib.${system}) buildFirefoxXpiAddon;
  inherit (pkgs.hostPlatform) system;

  fPkgs = self'.packages;
  cfg = config.shawn8901.desktop;
  firefox-addon-packages = inputs'.firefox-addons.packages;
in
{

  options = {
    shawn8901.desktop = {
      enable = mkEnableOption "my desktop settings for home manager";
    };
  };
  config = mkIf cfg.enable {

    sops = {
      secrets = {
        attic = {
          path = "${config.xdg.configHome}/attic/config.toml";
        };
      };
    };

    xdg = {
      enable = true;
      mime.enable = true;
      configFile."chromium-flags.conf".text = ''
        --ozone-platform-hint=auto
        --enable-features=WaylandWindowDecorations
      '';
    };
    services = {
      nextcloud-client = {
        enable = true;
        startInBackground = true;
      };
      gpg-agent = lib.mkMerge [
        { enable = true; }
        (lib.optionalAttrs (!(config.services.gpg-agent ? pinteryPackage)) { })
        (lib.optionalAttrs (config.services.gpg-agent ? pinteryPackage) {
          pinteryPackage = pkgs.pinentry-qt;
        })
      ];
    };

    home.packages =
      with pkgs;
      [
        samba
        nextcloud-client
        keepassxc
        (discord.override {
          nss = pkgs.nss_latest;
          withOpenASAR = true;
        })
        vlc
        plasma-integration
        libreoffice-qt
        krita

        nix-tree
        nixpkgs-review
      ]
      ++ (with fPkgs; [
        deezer
        nas
        vdhcoapp
        fPkgs.generate-zrepl-ssl
      ]);

    programs = {
      firefox = lib.mkMerge [
        {
          enable = true;
          package = pkgs.firefox;
          profiles."shawn" = {
            extensions = with firefox-addon-packages; [
              ublock-origin
              umatrix
              keepassxc-browser
              plasma-integration
              h264ify
              # firefox addons are from a input, that does not share pkgs with the host and some can not pass a
              # nixpkgs.config.allowUnfreePredicate to a flake input.
              # So overriding the stdenv is the only solution here to use the hosts nixpkgs.config.allowUnfreePredicate.
              (tampermonkey.override { inherit (pkgs) stdenv fetchurl; })
              (betterttv.override { inherit (pkgs) stdenv fetchurl; })

              # Download all plugins which are not in the repo manually
              (buildFirefoxXpiAddon {
                pname = "Video-DownloadHelper";
                version = "8.2.2.8";
                addonId = "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}";
                url = "https://addons.mozilla.org/firefox/downloads/file/4251369/video_downloadhelper-8.2.2.8.xpi";
                sha256 = "sha256-l1+fZvdrT4BVMWQZxklQpTKqXLQBj/u5Js8pPtXzAN0=";
                meta = { };
              })
            ];
            settings = {
              "app.update.auto" = false;
              "browser.crashReports.unsubmittedCheck.enabled" = false;
              "browser.newtab.preload" = false;
              "browser.newtabpage.activity-stream.enabled" = false;
              "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
              "browser.newtabpage.activity-stream.telemetry" = false;
              "browser.ping-centre.telemetry" = false;
              "browser.safebrowsing.malware.enabled" = true;
              "browser.safebrowsing.phishing.enabled" = true;
              "browser.send_pings" = false;
              "device.sensors.enabled" = false;
              "dom.battery.enabled" = false;
              "dom.webaudio.enabled" = false;
              "experiments.enabled" = false;
              "experiments.supported" = false;
              "privacy.donottrackheader.enabled" = true;
              "privacy.firstparty.isolate" = true;
              "privacy.trackingprotection.cryptomining.enabled" = true;
              "privacy.trackingprotection.enabled" = true;
              "privacy.trackingprotection.fingerprinting.enabled" = true;
              "privacy.trackingprotection.pbmode.enabled" = true;
              "privacy.trackingprotection.socialtracking.enabled" = true;
              "security.ssl.errorReporting.automatic" = false;
              "services.sync.engine.addons" = false;
              "services.sync.addons.ignoreUserEnabledChanges" = true;
              "toolkit.telemetry.archive.enabled" = false;
              "toolkit.telemetry.bhrPing.enabled" = false;
              "toolkit.telemetry.enabled" = false;
              "toolkit.telemetry.firstShutdownPing.enabled" = false;
              "toolkit.telemetry.hybridContent.enabled" = false;
              "toolkit.telemetry.newProfilePing.enabled" = false;
              "toolkit.telemetry.reportingpolicy.firstRun" = false;
              "toolkit.telemetry.server" = "";
              "toolkit.telemetry.shutdownPingSender.enabled" = false;
              "toolkit.telemetry.unified" = false;
              "toolkit.telemetry.updatePing.enabled" = false;
              "gfx.webrender.compositor.force-enabled" = true;
              "browser.cache.disk.enable" = false;
              "browser.cache.memory.enable" = true;
              "extensions.pocket.enabled" = false;
              "media.ffmpeg.vaapi.enabled" = true;
              "media.ffvpx.enabled" = false;
              "media.navigator.mediadatadecoder_vpx_enabled" = true;
              "media.rdd-vpx.enabled" = false;
            };
          };
        }
        (lib.optionalAttrs (config.programs.firefox ? nativeMessagingHosts) {
          nativeMessagingHosts = [ fPkgs.vdhcoapp ];
        })
      ];

      vscode = {
        enable = true;
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;
        mutableExtensionsDir = false;
        package = pkgs.vscode;
        extensions = with pkgs.vscode-extensions; [
          # general stuff
          mhutchie.git-graph
          editorconfig.editorconfig
          mkhl.direnv
          usernamehw.errorlens

          # nix dev
          jnoortheen.nix-ide

          # python dev
          ms-python.python
          ms-python.vscode-pylance

          # typescript dev
          esbenp.prettier-vscode
          wix.vscode-import-cost

          # rust dev
          rust-lang.rust-analyzer
          vadimcn.vscode-lldb
        ];
        keybindings = [
          {
            "key" = "ctrl+d";
            "command" = "-editor.action.addSelectionToNextFindMatch";
            "when" = "editorFocus";
          }
          {
            "key" = "ctrl+d";
            "command" = "editor.action.deleteLines";
            "when" = "textInputFocus && !editorReadonly";
          }
          {
            "key" = "ctrl+shift+k";
            "command" = "-editor.action.deleteLines";
            "when" = "textInputFocus && !editorReadonly";
          }
        ];
        userSettings = {
          "[nix]" = {
            "editor.insertSpaces" = true;
            "editor.tabSize" = 2;
            "editor.autoIndent" = "full";
            "editor.quickSuggestions" = {
              "other" = true;
              "comments" = false;
              "strings" = true;
            };
            "editor.formatOnSave" = true;
            "editor.formatOnPaste" = true;
            "editor.formatOnType" = false;
          };
          "[rust]" = {
            "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          };
          "[python]" = {
            "editor.formatOnSave" = true;
            "editor.formatOnPaste" = true;
            "editor.formatOnType" = false;
          };
          "[typescript]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "editor.tabSize" = 2;
          "terminal.integrated.persistentSessionReviveProcess" = "never";
          "terminal.integrated.enablePersistentSessions" = false;
          "terminal.integrated.fontFamily" = "MesloLGS Nerd Font Mono";
          "files.trimFinalNewlines" = true;
          "files.insertFinalNewline" = true;
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.formatOnSave" = true;
          "nix.enableLanguageServer" = true;
          "nix.formatterPath" = "${getExe pkgs.nixfmt-rfc-style}";
          "nix.serverPath" = "${getExe pkgs.nil}";
          "nix.serverSettings" = {
            "nil" = {
              "diagnostics" = {
                "ignored" = [
                  "unused_binding"
                  "unused_with"
                ];
              };
              "formatting" = {
                "command" = [ "${getExe pkgs.nixfmt-rfc-style}" ];
              };
            };
          };
        };
      };

      vim = {
        enable = true;
        defaultEditor = true;
        extraConfig = ''
          set nocompatible
          filetype indent on
          syntax on
          set hidden
          set wildmenu
          set showcmd
          set incsearch
          set hlsearch
          set backspace=indent,eol,start
          set autoindent
          set nostartofline
          set ruler
          set laststatus=2
          set confirm
          set visualbell
          set t_vb=
          set cmdheight=2
          set number
          set notimeout ttimeout ttimeoutlen=200
          set pastetoggle=<F11>
          set tabstop=8
          set shiftwidth=4
          set softtabstop=4
          set expandtab
          map Y y$
          nnoremap <C-L> :nohl<CR><C-L>
        '';
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
        config = {
          "global" = {
            "warn_timeout" = "10s";
            "load_dotenv" = true;
          };
          "whitelist" = {
            prefix = [ "${config.home.homeDirectory}/dev" ];
          };
        };
      };

      git = {
        enable = true;
        userName = "Shawn8901";
        userEmail = "shawn8901@googlemail.com";
        extraConfig = {
          init = {
            defaultBranch = "main";
          };
          push = {
            autoSetupRemote = "true";
          };
        };
      };

      gh = {
        enable = true;
        # Workaround for https://github.com/nix-community/home-manager/issues/4744
        settings = {
          version = 1;
        };
        extensions = [
          pkgs.gh-dash
          fPkgs.gh-poi
        ];
      };
      ssh = {
        enable = true;
        matchBlocks = {
          tank = {
            hostname = "tank";
            user = "shawn";
          };
          shelter = {
            hostname = "shelter.pointjig.de";
            user = "shawn";
          };
          watchtower = {
            hostname = "watchtower.pointjig.de";
            user = "shawn";
          };
          sap = {
            hostname = "clansap.org";
            user = "root";
          };
          next = {
            hostname = "next.clansap.org";
            user = "root";
          };
          pointjig = {
            hostname = "pointjig.de";
            user = "shawn";
          };
          sapsrv01 = {
            hostname = "sapsrv01.clansap.org";
            user = "root";
          };
          sapsrv02 = {
            hostname = "sapsrv02.clansap.org";
            user = "root";
          };
        };
      };
    };
  };
}
