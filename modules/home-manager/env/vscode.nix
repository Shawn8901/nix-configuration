{ config, lib, pkgs, ... }:
let
  cfg = config.env.vscode;
  system = pkgs.hostPlatform.system;
in
with lib; {
  options = {
    env.vscode = {
      enable = mkEnableOption "Enable vsocde on the environment";
    };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ nixpkgs-fmt nil ];

    programs.vscode = {
      enable = true;
      enableExtensionUpdateCheck = false;
      enableUpdateCheck = false;
      package = pkgs.vscode;
      extensions = with pkgs.vscode-extensions; [
        editorconfig.editorconfig
        esbenp.prettier-vscode
        jnoortheen.nix-ide
        mkhl.direnv
        ms-python.python
        ms-python.vscode-pylance
        mhutchie.git-graph
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
        "files.trimFinalNewlines" = true;
        "files.insertFinalNewline" = true;
        "diffEditor.ignoreTrimWhitespace" = false;
        "editor.formatOnSave" = true;
        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
        "nix.serverSettings" = {
          "nil" = {
            "diagnostics" = {
              "ignored" = [ "unused_binding" "unused_with" ];
            };
            "formatting" = {
              "command" = [ "nixpkgs-fmt" ];
            };
          };
        };
      };
    };
  };
}
