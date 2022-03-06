{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nvd
    git
    wget
    git
    fzf
    gnumake
    tree
    htop
    nano
    neofetch
    unzip
  ];
}
