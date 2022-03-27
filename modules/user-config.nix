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

  users.mutableUsers = false;
  users.users.root = {
    hashedPassword = config.my.secrets.root.hashedPassword;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
  };
  nix.settings.trusted-users = [ "shawn" ];
  users.users.shawn = {
    hashedPassword = config.my.secrets.shawn.hashedPassword;
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" "video" "audio" "libvirtd" "plugdev" "adbusers" "scanner" "lp" ];
    uid = 1000;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
  };

  environment = {
    variables.EDITOR = "nano";
  };
}
