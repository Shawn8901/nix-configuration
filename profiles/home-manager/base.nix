{
  pkgs,
  self',
  lib,
  ...
}: let
  fPkgs = self'.packages;
in {
  programs.zsh = {enable = true;};
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    userName = "Shawn8901";
    userEmail = "shawn8901@googlemail.com";
    ignores = ["*.swp"];
    extraConfig = {init = {defaultBranch = "main";};};
  };
}
