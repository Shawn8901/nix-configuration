{
  self',
  config,
  lib,
  pkgs,
  inputs',
  ...
}: let
  fPkgs = self'.packages;
  attic = inputs'.attic.packages.attic-nixpkgs;
in {
  sops = {
    secrets = {
      attic = {path = "${config.xdg.configHome}/attic/config.toml";};
    };
  };

  home.packages = with pkgs;
    [
      alejandra
      nil
      nix-tree
      nixpkgs-review
      # (attic.override {
      #   nix = config.nix.package;
      #   clientOnly = true;
      # })
    ]
    ++ [fPkgs.generate-zrepl-ssl];

  programs.vscode = {
    enable = true;
    enableExtensionUpdateCheck = false;
    enableUpdateCheck = false;
    mutableExtensionsDir = false;
    package = pkgs.vscode;
    extensions = with pkgs.vscode-extensions; [
      mhutchie.git-graph
      editorconfig.editorconfig
      mkhl.direnv
      usernamehw.errorlens

      jnoortheen.nix-ide

      ms-python.python
      ms-python.vscode-pylance

      esbenp.prettier-vscode
      wix.vscode-import-cost
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
        "load_dotenv" = true;
      };
      "whitelist" = {
        prefix = ["${config.home.homeDirectory}/dev"];
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Shawn8901";
    userEmail = "shawn8901@googlemail.com";
    ignores = ["*.swp"];
    extraConfig = {
      init = {defaultBranch = "main";};
      push = {autoSetupRemote = "true";};
    };
  };

  programs.gh = {
    enable = true;
    extensions = [pkgs.gh-dash fPkgs.gh-poi];
  };
  programs.ssh = {
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
      cache = {
        hostname = "cache.pointjig.de";
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
}
