{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    enableGlobalCompInit = true;
    interactiveShellInit = ''
      neofetch
    '';
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "command-not-found" "cp" "zsh-interactive-cd" ];
      theme = "fletcherm";
    };
  };
  environment.pathsToLink = [ "/share/zsh" ];
}
