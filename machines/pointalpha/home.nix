{ self, config, pkgs, ... }:

{

  home-manager.users.shawn = {
    home.packages = with pkgs; [
      # Administration
      remmina
      authy

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
      discord
      teamspeak_client
      signal-desktop

      # Moonlander
      wally-cli

      # Entertainment
      vlc

      # STFC
      virt-manager
      autoadb
      scrcpy

      # Games
      s25rttr
      proton-ge-custom

      # Shell
      stfc
      nas

      haguichi

      protontricks

      samba

    ] ++ (with pkgs.nur.repos.wolfangaukang; [ vdhcoapp ]);

    home.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-custom}";
    };

    env = {
      vscode.enable = true;
      browser.enable = true;
    };

    services = {
      nextcloud-client = {
        startInBackground = true;
      };
      gpg-agent = {
        enable = true;
        pinentryFlavor = "qt";
      };
      autoadb.enable = true;
      noisetorch = {
        enable = true;
        threshold = 75;
        device = "alsa_input.usb-WOER_WOER_20180508-00.iec958-stereo";
        deviceUnit = ''dev-snd-by\x2did-usb\x2dWOER_WOER_20180508\x2d00.device'';
      };
    };
  };
}
