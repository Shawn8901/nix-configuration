{ self, system, nPkgs, ... }@inputs:
{ config, pkgs, ... }:
let
  fPkgs = self.packages.${system};
in
{
  home-manager.users.shawn = {
    home.packages = with pkgs;
      with fPkgs;
      [
        remmina
        samba
        chromium
        portfolio
        jameica
        libreoffice
        inkscape
        gimp
        nextcloud-client
        keepassxc
        (discord.override { nss = pkgs.nss_latest; withOpenASAR = true; })
        teamspeak_client
        signal-desktop
        wally-cli
        vlc
        proton-ge-custom
        wineWowPackages.unstableFull
        s25rttr
        nas

        sqlitebrowser
        # virt-manager
        # scrcpy
        # stfc
      ] ++ (with nPkgs.nur.repos.wolfangaukang; [ vdhcoapp ]);

    home.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${fPkgs.proton-ge-custom}";
    };

    env = {
      vscode.enable = true;
      browser.enable = true;
    };
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
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
