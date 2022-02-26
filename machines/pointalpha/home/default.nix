{ self, config, pkgs, ... }:
let
  nas_credentials = config.my.secrets.nas;
in {

  home-manager.users.shawn = {
    imports = [
      ../../../home/browser.nix
      ../../../home/git.nix
      ../../../home/vscode.nix
    ];
    home.packages = with pkgs; [
      # Administration      
      remmina

      # Finance
      portfolio
      jameica

      # Password and Sync
      nextcloud-client
      keepassxc
      git-crypt

      # Social
      discord
      teamspeak_client
      #ts3overlay

      # Moonlander
      wally-cli

      # Entertainment
      vlc

      # STFC
      virt-manager
      autoadb
      scrcpy
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
          ExecStart = "${pkgs.autoadb}/bin/autoadb ${pkgs.scrcpy}/bin/scrcpy -b 16M -s '{}'";
        };
      };
      "noisetorch" = {
        Unit = {
          Description = "Noisetorch Noise Cancelling";
          Requires = "sys-devices-pci0000:00-0000:00:07.1-0000:2e:00.3-usb5-5\\x2d3-5\\x2d3:1.0-sound-card2-controlC2.device";
          After = "sys-devices-pci0000:00-0000:00:07.1-0000:2e:00.3-usb5-5\\x2d3-5\\x2d3:1.0-sound-card2-controlC2.device";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          Type = "simple";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.noisetorch}/bin/noisetorch -i -s alsa_input.usb-WOER_WOER_20180508-00.analog-stereo -t 70";
          ExecStop = "${pkgs.noisetorch}/bin/noisetorch -u";
          Restart = "on-failure";
          RestartSec = 3;
        };
      };
    };

    programs.zsh = {
      enable = true;
      shellAliases = {
        nas_mount= "sudo mount -t cifs //tank.fritz.box/joerg /media/nas -o ${nas_credentials},iocharset=utf8,uid=1000,gid=1000,forcegid,forceuid,vers=3.0";
        nas_umount = "sudo umount /media/nas";
        stfc = "adb connect blissos";
      };
    };

    programs.gpg.enable = true;
    services.gpg-agent = {
      enable = true;
      pinentryFlavor = "gnome3";
    };

    dconf.settings."org/gnome/shell".enabled-extensions = with pkgs; [
      gnomeExtensions.caffeine.passthru.extensionUuid
      gnomeExtensions.alphabetical-app-grid.passthru.extensionUuid
      gnomeExtensions.screenshot-tool.passthru.extensionUuid
    ];
  };
}
