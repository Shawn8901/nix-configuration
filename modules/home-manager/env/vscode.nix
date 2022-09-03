inputs:
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

    home.packages = with pkgs; [ nixpkgs-fmt rnix-lsp python3.pkgs.isort python3.pkgs.autopep8 pkgs.pur ];

    programs.vscode = {
      enable = true;
      extensions = (with inputs.nix-vscode-marketplace.packages.${inputs.system}.vscode; [
        ms-python.python
        ms-python.isort
        ms-python.vscode-pylance
        editorconfig.editorconfig
        jnoortheen.nix-ide
        mkhl.direnv
      ]);
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
        "nix.formatterPath" = "nixpkgs-fmt";
      };
    };
  };
}
