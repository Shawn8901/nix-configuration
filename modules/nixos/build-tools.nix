{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    htop
    nano
    vim
    nix-output-monitor
    sops
  ];
}
