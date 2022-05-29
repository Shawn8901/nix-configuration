{ self, ... }@inputs:
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
    neofetch
    unzip
    age
    self.packages.x86_64-linux.agenix
    ncdu
  ];
}
