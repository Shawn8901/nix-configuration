{ pkgs, self', lib, ... }:
let fPkgs = self'.packages;
in {
  programs.zsh = { enable = true; };
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };
}
