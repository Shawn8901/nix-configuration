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
    sops.secrets = {
      shawn = {
        sopsFile = ../../files/secrets-common.yaml;
        neededForUsers = true;
      };
      root = {
        sopsFile = ../../files/secrets-common.yaml;
        neededForUsers = true;
      };
    };

    programs.command-not-found.enable = false;
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      enableGlobalCompInit = true;
      syntaxHighlighting.enable = true;
      autosuggestions.enable = true;
      promptInit = ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${../../files/p10k.zsh}
      '';
      interactiveShellInit = ''
        bindkey '^[[1;5C' forward-word        # ctrl right
        bindkey '^[[1;5D' backward-word       # ctrl left
        bindkey '^H' backward-kill-word
        bindkey '5~' kill-word
      '';
    };
    fonts = {
      enableDefaultFonts = true;
      fontDir.enable = true;
      fontconfig.enable = lib.mkDefault true;
      fonts = [pkgs.liberation_ttf pkgs.noto-fonts (pkgs.nerdfonts.override {fonts = ["Meslo" "DroidSansMono" "LiberationMono" "Terminus"];})];
    };

    users.mutableUsers = false;
    users.users.root = {
      passwordFile = config.sops.secrets.root.path;
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
      ];
    };
    users.users.shawn = {
      passwordFile = config.sops.secrets.shawn.path;
      isNormalUser = true;
      group = "users";
      extraGroups = ["wheel"];
      uid = 1000;
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
      ];
    };
    environment.systemPackages = [pkgs.fzf]; # Used by zsh-interactive-cd
    environment = {variables.EDITOR = "nano";};
  };
}
