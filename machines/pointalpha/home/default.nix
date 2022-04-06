{ self, config, pkgs, ... }:

{

  home-manager.users.shawn = {
    imports = [
      ./browser.nix
      ./vscode.nix
    ];

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

    ] ++ (with pkgs.nur.repos.wolfangaukang; [ vdhcoapp ]);

    home.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-custom}";
    };

    services.nextcloud-client = {
      startInBackground = true;
    };

    systemd.user.services = {
      "autoadb" = {
        Unit = {
          Description = "Start autoadb";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          ExecStart = "${pkgs.autoadb}/bin/autoadb ${pkgs.scrcpy}/bin/scrcpy -b 16M --render-driver opengles2 -s '{}'";
          Environment = [ "DISPLAY=:1" "XAUTHORITY=/run/user/1000/gdm/Xauthority" ];
        };
      };
      "noisetorch" = {
        Unit = {
          Description = "Noisetorch Noise Cancelling";
          Requires = ''dev-snd-by\x2did-usb\x2dWOER_WOER_20180508\x2d00.device'';
          After = ''dev-snd-by\x2did-usb\x2dWOER_WOER_20180508\x2d00.device'';
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          Type = "simple";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.noisetorch}/bin/noisetorch -i -s alsa_input.usb-WOER_WOER_20180508-00.iec958-stereo -t 50";
          ExecStop = "${pkgs.noisetorch}/bin/noisetorch -u";
          Restart = "on-failure";
          RestartSec = 3;
          Nice = -10;
        };
      };
    };

    programs.gpg.enable = true;
    services.gpg-agent = {
      enable = true;
      pinentryFlavor = "qt";
    };
  };
}
