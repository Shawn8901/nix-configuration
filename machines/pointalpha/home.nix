{ self, config, pkgs, nPkgs, ... }:
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
        libreoffice
        inkscape
        gimp
        nextcloud-client
        keepassxc
        (discord.override { nss = pkgs.nss_latest; })
        teamspeak_client
        signal-desktop
        wally-cli
        vlc
        wineWowPackages.unstableFull
        s25rttr
        nas

        virt-manager

        sqlitebrowser
      ] ++ (with pkgs.nur.repos.wolfangaukang; [ vdhcoapp ]);

    env = {
      vscode.enable = true;
      browser.enable = true;
    };
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    programs.direnv.enableZshIntegration = true;
    programs.gh.enable = true;
    xdg.enable = true;
    xdg.mime.enable = true;

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
