_: {
  home.stateVersion = "23.05";

  programs.zsh = {
    enable = true;
  };
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };
  manual.manpages.enable = false;
}
