{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Shawn8901";
    userEmail = "shawn8901@googlemail.com";
    ignores = [ "*.swp" ];
    extraConfig = {
      init = { defaultBranch = "main"; };
    };
  };
}
