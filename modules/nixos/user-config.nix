{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.env.user-config;
in {
  options = {
    env.user-config = {
      enable = lib.mkEnableOption "Use general user config on that system";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      shawn_password_file = {file = ../../secrets/shawn_password.age;};
      root_password_file = {file = ../../secrets/root_password.age;};
    };

    programs.command-not-found.enable = false;
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      enableGlobalCompInit = true;
      syntaxHighlighting.enable = true;
      autosuggestions.enable = true;
      ohMyZsh = {
        enable = true;
        plugins = ["git" "cp" "zsh-interactive-cd"];
        theme = "fletcherm";
      };
    };
    environment.pathsToLink = ["/share/zsh"];

    users.mutableUsers = false;
    users.users.root = {
      passwordFile = config.age.secrets.root_password_file.path;
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
      ];
    };
    users.users.shawn = {
      passwordFile = config.age.secrets.shawn_password_file.path;
      isNormalUser = true;
      group = "users";
      extraGroups = ["wheel"];
      uid = 1000;
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
      ];
    };

    environment = {variables.EDITOR = "nano";};
  };
}
