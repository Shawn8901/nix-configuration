{
  config,
  lib,
  pkgs,
  ...
}: {
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
      source "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
      source "${pkgs.fzf}/share/fzf/completion.zsh"
      source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
      source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
      source "${pkgs.zsh-fzf-tab}/share/fzf-tab/lib/zsh-ls-colors/ls-colors.zsh"
    '';
    interactiveShellInit = ''
      bindkey '^[[1;5C' forward-word        # ctrl right
      bindkey '^[[1;5D' backward-word       # ctrl left
      bindkey '^H' backward-kill-word
      bindkey '5~' kill-word
    '';
  };
  fonts = {
    enableDefaultFonts = !config.environment.noXlibs;
    fontconfig.enable = !config.environment.noXlibs;
    fonts = [(pkgs.nerdfonts.override {fonts = ["Meslo" "DroidSansMono" "LiberationMono" "Terminus"];})];
  };

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;
    users = {
      root = {
        passwordFile = config.sops.secrets.root.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
        ];
      };
      shawn = {
        passwordFile = config.sops.secrets.shawn.path;
        isNormalUser = true;
        group = "users";
        extraGroups = ["wheel"];
        uid = 1000;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
        ];
      };
    };
  };

  environment.systemPackages = [pkgs.fzf]; # Used by zsh-interactive-cd
  environment = {variables.EDITOR = "nano";};
}