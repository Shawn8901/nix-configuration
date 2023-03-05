{
  self,
  config,
  pkgs,
  ...
}: let
  inherit (pkgs.hostPlatform) system;

  fPkgs = self.packages.${system};
in {
  home-manager.users.shawn = {
    home.packages = with pkgs;
      [
        remmina
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

    env = {
      vscode.enable = true;
      browser.enable = true;
    };
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
    programs.dircolors = {
      enable = true;
      enableZshIntegration = true;
    };
    programs.gh = {
      enable = true;
      extensions = [fPkgs.gh-poi];
    };
    xdg.enable = true;
    xdg.mime.enable = true;
    xdg.configFile."chromium-flags.conf".text = ''
      --ozone-platform-hint=auto
      --enable-features=WaylandWindowDecorations
    '';
    services = {
      nextcloud-client = {startInBackground = true;};
      gpg-agent = {
        enable = true;
        pinentryFlavor = "qt";
      };
    };
  };
}
