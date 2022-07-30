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
        # Administration
        remmina

        # Finance
        portfolio
        jameica

        libreoffice
        inkscape
        gimp

        # Password and Sync
        nextcloud-client
        keepassxc

        # Social
        (discord.override { nss = pkgs.nss_latest; })
        teamspeak_client
        signal-desktop

        # Moonlander
        wally-cli

        # Entertainment
        vlc

        # STFC
        virt-manager
        scrcpy

        # Games
        s25rttr
        proton-ge-custom
        protontricks

        # Shell
        stfc
        nas

        samba
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
      autoadb.enable = true;
      noisetorch = {
        enable = true;
        package = self.nixosConfigurations.pointalpha.config.programs.noisetorch.package;
        threshold = 75;
        device = "alsa_input.usb-WOER_WOER_20180508-00.iec958-stereo";
        deviceUnit = "dev-snd-by\\x2did-usb\\x2dWOER_WOER_20180508\\x2d00.device";
      };
    };
  };
}
