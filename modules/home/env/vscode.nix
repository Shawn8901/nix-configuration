{ config, lib, pkgs, ... }:
let
  cfg = config.env.vscode;
in
with lib;
{
  options = {
    env.vscode = { enable = mkEnableOption "Enable vsocde on the environment"; };
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      extensions = (with pkgs.vscode-extensions; [
        ms-python.python
        ms-python.vscode-pylance
        editorconfig.editorconfig

        esbenp.prettier-vscode

        golang.go

        redhat.vscode-yaml

        eamodio.gitlens

        bbenoist.nix

        kamadorueda.alejandra

      ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "code-python-isort";
          publisher = "freakypie";
          version = "0.0.3";
          sha256 = "0kzz5k2yh0gk57hgf3ykbrq2qchv209gmbm6milfvnnds0aq3s9r";
        }
        {
          name = "vscode-typescript-tslint-plugin";
          publisher = "ms-vscode";
          version = "1.3.3";
          sha256 = "1xjspcmx5p9x8yq1hzjdkq3acq52nilpd9bm069nsvrzzdh0n891";
        }
        {
          name = "tsimporter";
          publisher = "pmneo";
          version = "2.0.1";
          sha256 = "124jyk9iz3spq8q17z79lqgcwfabbvldcq243xbzbjmbb01ds3i5";
        }
        {
          name = "better-align";
          publisher = "wwm";
          version = "1.1.6";
          sha256 = "sha256-kJJi+0I/ZCbWmLR8zrhMALY0LwEMMM7/8Jj2pLa6u9E=";
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
          "editor.formatOnSave" = false;
          "editor.formatOnPaste" = false;
          "editor.formatOnType" = false;
        };
      };
    };
  };
}
