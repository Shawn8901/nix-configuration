{ self, config, pkgs, ... }:
let
  system = pkgs.hostPlatform.system;
  fPkgs = self.packages.${system};
in
{
  home-manager.users.shawn = {
    home.packages = with pkgs;
      with fPkgs;
      [
        remmina
        samba
        portfolio
        jameica
        pytr
        libreoffice-qt
        inkscape
        gimp
        nextcloud-client
        keepassxc
        (discord.override { nss = pkgs.nss_latest; })
        teamspeak_client
        signal-desktop
        rogerrouter
        wally-cli
        vlc
        wineWowPackages.waylandFull
        s25rttr
        nas

        virt-manager

        sqlitebrowser
        generate-zrepl-ssl
        vdhcoapp
      ];

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
      extensions = [ fPkgs.gh-poi ];
    };
    xdg.enable = true;
    xdg.mime.enable = true;
    xdg.configFile."chromium-flags.conf".text = ''
      --ozone-platform-hint=auto
      --enable-features=WaylandWindowDecorations
    '';

    services = {
      nextcloud-client = { startInBackground = true; };
      gpg-agent = {
        enable = true;
        pinentryFlavor = "qt";
      };
      autoadb.enable = false;
      noisetorch = {
        enable = true;
        package = config.programs.noisetorch.package;
        threshold = 30;
        device = "alsa_input.usb-WOER_WOER_20180508-00.iec958-stereo";
        deviceUnit = "dev-snd-by\\x2did-usb\\x2dWOER_WOER_20180508\\x2d00.device";
      };
    };
  };
}
