_:
{ config, lib, pkgs, ... }:
let cfg = config.env.vscode;
in
with lib; {
  options = {
    env.vscode = {
      enable = mkEnableOption "Enable vsocde on the environment";
    };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ nixpkgs-fmt rnix-lsp python3.pkgs.isort ];

    programs.vscode = {
      enable = true;
      extensions = (with pkgs.vscode-extensions; [
        ms-python.python
        ms-python.vscode-pylance
        editorconfig.editorconfig
        jnoortheen.nix-ide
        arrterian.nix-env-selector
      ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "code-python-isort";
          publisher = "freakypie";
          version = "0.0.3";
          sha256 = "0kzz5k2yh0gk57hgf3ykbrq2qchv209gmbm6milfvnnds0aq3s9r";
        }
        {
          name = "direnv";
          publisher = "mkhl";
          version = "0.6.1";
          sha256 = "sha256-5/Tqpn/7byl+z2ATflgKV1+rhdqj+XMEZNbGwDmGwLQ=";
        }
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
        "editor.tabSize" = 2;
        "files.trimFinalNewlines" = true;
        "files.insertFinalNewline" = true;
        "diffEditor.ignoreTrimWhitespace" = false;
        "editor.formatOnSave" = true;
        "nix.enableLanguageServer" = true;
      };
    };
  };
}
