{ self, system, agenix, ... }@inputs:
{ pkgs, ... }:

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
    unzip
    ncdu
    graphviz
    nix-du
    agenix.defaultPackage.${system}
  ];
}
