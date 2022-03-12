{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    extensions = (with pkgs.vscode-extensions; [
      ms-python.python
      ms-python.vscode-pylance

      esbenp.prettier-vscode

      golang.go

      redhat.vscode-yaml

      eamodio.gitlens

      bbenoist.nix
      b4dm4n.vscode-nixpkgs-fmt

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
    ];
  };
}
