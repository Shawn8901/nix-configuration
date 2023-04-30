{
  self,
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.hostPlatform) system;
  inherit (hmConfig.sops) secrets;
  userName = "shawn";
  hmConfig = config.home-manager.users.${userName};
  user = config.users.users.${userName};

  fPkgs = self.packages.${system};
in {
  home-manager.users.${userName} = {
    sops = {
      age.keyFile = "${hmConfig.xdg.configHome}/sops/age/keys.txt";
      defaultSopsFile = ./secrets-home.yaml;
      defaultSymlinkPath = "/run/user/${toString user.uid}/secrets";
      defaultSecretsMountPoint = "/run/user/${toString user.uid}/secrets.d";
      secrets = {
        attic = {path = "${hmConfig.xdg.configHome}/attic/config.toml";};
      };
    };

    home.packages = with pkgs;
      [
        samba
        libreoffice-qt
        krita
        nextcloud-client
        keepassxc
        (discord.override {nss = pkgs.nss_latest;})
        vlc
        plasma-integration
        nix-tree
      ]
      ++ (with fPkgs; [
        deezer
        nas
      ]);

    shawn8901 = {
      development.enable = true;
      browser.enable = true;
    };
    programs.dircolors = {
      enable = true;
      enableZshIntegration = true;
    };
    xdg.enable = true;
    xdg.mime.enable = true;
    xdg.configFile = {
      "chromium-flags.conf".text = ''
        --ozone-platform-hint=auto
        --enable-features=WaylandWindowDecorations
      '';
    };
    services = {
      nextcloud-client = {startInBackground = true;};
      gpg-agent = {
        enable = true;
        pinentryFlavor = "qt";
      };
    };
  };
}
