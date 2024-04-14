{
  self,
  config,
  flakeConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    optionalAttrs
    versionOlder
    ;

  cfg = config.shawn8901.managed-user;
in
{
  options = {
    shawn8901.managed-user = {
      enable = mkEnableOption "preconfigured users";
    };
  };
  config = mkIf cfg.enable {

    sops.secrets = {
      shawn = {
        sopsFile = ../../../files/secrets-common.yaml;
        neededForUsers = true;
      };
      root = {
        sopsFile = ../../../files/secrets-common.yaml;
        neededForUsers = true;
      };
    };

    programs = lib.mkMerge [
      {
        zsh = {
          enable = true;
          enableCompletion = true;
          enableBashCompletion = true;
          enableGlobalCompInit = true;
          syntaxHighlighting.enable = true;
          autosuggestions.enable = true;
          promptInit = ''
            source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
            source "${../../../files/p10k.zsh}"

          '';
          interactiveShellInit = ''
            source "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
            source "${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
            source "${pkgs.zsh-fzf-tab}/share/fzf-tab/lib/zsh-ls-colors/ls-colors.zsh"

            bindkey '^[[1;5C' forward-word        # ctrl right
            bindkey '^[[1;5D' backward-word       # ctrl left
            bindkey '^H' backward-kill-word
            bindkey '5~' kill-word
          '';
        };
      }
      ((optionalAttrs (!versionOlder config.system.nixos.release "24.05") { fzf.enable = true; }))
    ];
    fonts = {
      fontconfig.enable = lib.mkDefault (!config.environment.noXlibs);
      enableDefaultPackages = lib.mkDefault (!config.environment.noXlibs);
      packages = [
        (pkgs.nerdfonts.override {
          fonts = [
            "Meslo"
            "DroidSansMono"
            "LiberationMono"
            "Terminus"
          ];
        })
      ];
    };

    users = {
      mutableUsers = false;
      defaultUserShell = pkgs.zsh;
      users = {
        root.hashedPasswordFile = config.sops.secrets.root.path;
        shawn = {
          isNormalUser = true;
          group = "users";
          extraGroups = [ "wheel" ];
          uid = 1000;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
          ];
          hashedPasswordFile = config.sops.secrets.shawn.path;
        };
      };
    };

    # Needed to access secrets for the builder.
    nix.settings.trusted-users = [ "shawn" ];

    environment.systemPackages = mkIf (versionOlder config.system.nixos.release "24.05") [ pkgs.fzf ];
  };
}
