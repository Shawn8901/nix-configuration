{
  self,
  inputs,
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
        samba
        portfolio
        libreoffice-qt
        krita
        nextcloud-client
        keepassxc
        (discord.override {nss = pkgs.nss_latest;})
        teamspeak_client
        signal-desktop
        wally-cli
        vlc
        plasma-integration
        exodus
        nix-tree
      ]
      ++ (with fPkgs; [
        deezer
        generate-zrepl-ssl
        jameica-fhs
        nas
        pytr
        rogerrouter
        s25rttr
        vdhcoapp
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
      autoadb.enable = false;
      noisetorch = {
        enable = true;
        threshold = 30;
        device = "alsa_input.usb-WOER_WOER_20180508-00.iec958-stereo";
        deviceUnit = "dev-snd-by\\x2did-usb\\x2dWOER_WOER_20180508\\x2d00.device";
        inherit (config.programs.noisetorch) package;
      };
    };
  };
}
