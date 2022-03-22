{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nvd
    git
    jq
    wget
    git
    fzf
    gnumake
    tree
    htop
    nano
    neofetch
    unzip
    python3
    python3Packages.pip
  ];
}
