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
    };

    programs.zsh = {
      enable = true;
      shellAliases = {
        nas_mount= "sudo mount -t cifs //tank.fritz.box/joerg /media/nas -o ${nas_credentials},iocharset=utf8,uid=1000,gid=1000,forcegid,forceuid,vers=3.0";
        nas_umount="sudo umount /media/nas";
        stfc="adb connect blissos";
      };
    };

    programs.gpg.enable = true;
    services.gpg-agent = {
      enable = true;
      pinentryFlavor = "gnome3";
    };
  };
}
