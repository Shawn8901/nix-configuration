{ self, config, pkgs, ... }:
let
  nas_credentials = config.my.secrets.nas;
in
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
      git-crypt

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

      xorg.xeyes

      s25rttr
    ];

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
          Environment = ["DISPLAY=:1" "XAUTHORITY=/run/user/1000/gdm/Xauthority"];
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
          Nice=-10;
        };
      };
    };

    programs.zsh = {
      enable = true;
      shellAliases = {
        nas_mount = "sudo mount -t cifs //tank.fritz.box/joerg /media/nas -o ${nas_credentials},iocharset=utf8,uid=1000,gid=1000,forcegid,forceuid,vers=3.0";
        nas_umount = "sudo umount /media/nas";
        stfc = "adb connect blissos";
      };
    };

    programs.gpg.enable = true;
    services.gpg-agent = {
      enable = true;
      pinentryFlavor = "qt";
    };
  };
}
