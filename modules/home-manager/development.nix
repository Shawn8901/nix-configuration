{
  self,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.shawn8901.development;
  fPkgs = self.packages.${system};
  inherit (pkgs.hostPlatform) system;
in
  with lib; {
    options = {
      shawn8901.development = {
        enable = mkEnableOption "Enable vsocde on the environment";
      };
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [alejandra nil];

      programs.git = {
        enable = true;
        userName = "Shawn8901";
        userEmail = "shawn8901@googlemail.com";
        ignores = ["*.swp"];
        extraConfig = {init = {defaultBranch = "main";};};
      };

      programs.vscode = {
        enable = true;
        enableExtensionUpdateCheck = false;
        enableUpdateCheck = false;
        mutableExtensionsDir = false;
        package = pkgs.vscode;
        extensions = with pkgs.vscode-extensions; [
          editorconfig.editorconfig
          esbenp.prettier-vscode
          jnoortheen.nix-ide
          mkhl.direnv
          ms-python.python
          ms-python.vscode-pylance
          mhutchie.git-graph
          usernamehw.errorlens
          eamodio.gitlens
          rust-lang.rust-analyzer
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
          "nix.formatterPath" = "${pkgs.alejandra}/bin/alejandra";
          "nix.serverPath" = "${pkgs.nil}/bin/nil";
          "nix.serverSettings" = {
            "nil" = {
              "diagnostics" = {
                "ignored" = ["unused_binding" "unused_with"];
              };
              "formatting" = {
                "command" = ["alejandra"];
              };
            };
          };
        };
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
        config = {
          "global" = {
            "warn_timeout" = "10s";
            "load_dotenv" = "true";
          };
          "whitelist" = {
            prefix = "${config.home.homeDirectory}/dev";
          };
        };
      };
      programs.gh = {
        enable = true;
        extensions = [fPkgs.gh-poi];
      };
      programs.ssh = {
        enable = true;
        matchBlocks = {
          tank = {
            hostname = "tank";
            user = "root";
          };
          shelter = {
            hostname = "shelter.pointjig.de";
            user = "root";
          };
          cache = {
            hostname = "cache.pointjig.de";
            user = "root";
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
            user = "root";
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
  }
