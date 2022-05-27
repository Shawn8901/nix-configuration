{ config, pkgs, ... }:

{
  imports = [
    ./services/autoadb.nix
    ./services/noisetorch.nix
    ./env/vscode.nix
    ./env/browser.nix
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
}
