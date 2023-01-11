{ pkgs, inputs, ... }:
let
  system = pkgs.hostPlatform.system;
in
{
  environment.systemPackages = with pkgs; [
    nvd
    git
    jq
    wget
    fzf
    gnumake
    tree
    htop
    nano
    vim
    unzip
    ncdu
    graphviz
    nix-du
    nix-output-monitor
    inputs.agenix.defaultPackage.${system}
  ];
}
