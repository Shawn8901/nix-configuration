{ self, system, ... }@inputs:
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
    age
    self.packages.${system}.agenix
    ncdu
    graphviz
    nix-du
  ];
}
