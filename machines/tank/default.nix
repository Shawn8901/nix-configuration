{ self, config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  age.secrets = {
    ztank_key = {
      file = ../../secrets/ztank_key.age;
    };
    zrepl_tank = {
      file = ../../secrets/zrepl_tank.age;
    };
    ela_password_file = {
      file = ../../secrets/ela_password.age;
    };
    nextcloud_db_file = {
      file = ../../secrets/nextcloud_db.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    nextcloud_admin_file = {
      file = ../../secrets/nextcloud_admin.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
  };

  networking = {
    firewall = {
      allowedUDPPorts = [ ];
      allowedUDPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 8888 ];
      allowedTCPPortRanges = [ ];
    };
    networkmanager.enable = false;
    dhcpcd.enable = false;
    useNetworkd = true;
    useDHCP = false;
  };

  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "eno1";
          networkConfig.DHCP = "yes";
          networkConfig.Domains = "fritz.box ~box ~.";
        };
      };
      wait-online = {
        ignoredInterfaces = [ "enp4s0" ];
      };
    };
    services.backup-nextcloud = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      description = "Copy nextcloud stuff to dropbox";
      serviceConfig = {
        Type = "oneshot";
        User = "shawn";
        ExecStart = ''${pkgs.rclone}/bin/rclone copy /var/lib/nextcloud/data/shawn/files/ dropbox:'';
      };
    };
    timers.backup-nextcloud = {
      wantedBy = [ "timers.target" ];
      partOf = [ "backup-nextcloud.service" ];
      timerConfig = {
        OnCalendar = [ "daily" ];
        Persistent = true;
        OnBootSec = "15min";
      };
    };

    services.sched-shutdown = {
      description = "Scheduled shutdown";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''${pkgs.systemd}/bin/systemctl --force poweroff'';
      };
    };
    timers.sched-shutdown = {
      wantedBy = [ "timers.target" ];
      partOf = [ "sched-shutdown.service" ];
      timerConfig = {
        OnCalendar = [ "*-*-* 00:01:00" ];
      };
    };

    services.rtcwakeup = {
      description = "Automatic wakeup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${pkgs.util-linux}/bin/rtcwake -m no -u -t $(${pkgs.coreutils-full}/bin/date +\%s -d 'tomorrow 14:00')'';
      };
    };
    timers.rtcwakeup = {
      wantedBy = [ "timers.target" ];
      partOf = [ "sched-shutdown.service" ];
      timerConfig = {
        Persistent = true;
        OnBootSec = "1min";
        OnCalendar = [ "*-*-* 14:05" ];
      };
    };

    services."usb-backup-ela@" = {
      description = "Backups /media/daniela to usb hdd";
      serviceConfig = {
        Type = "simple";
        GuessMainPID = false;
        WorkingDirectory = "/media/daniela";
        ExecStart = ''${pkgs.usb-backup-ela}/bin/usb-backup-ela %I'';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    cifs-utils
    rclone
    coreutils-full
    util-linux
    beep
    usb-backup-ela
    udisks2
    rsync
  ];

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="block", ACTION=="add", ATTRS{idVendor}=="04fc", ATTRS{idProduct}=="0c25", ATTR{partition}=="2", TAG+="systemd", ENV{SYSTEMD_WANTS}="usb-backup-ela@%k.service"
    '';


    openssh.enable = true;
    resolved.enable = true;

    zfs.trim.enable = true;
    zfs.autoScrub.enable = true;
    zfs.autoScrub.pools = [ "rpool" "ztank" ];

    zrepl = {
      enable = true;
      settings = {
        global = {
          monitoring = [
            {
              type = "prometheus";
              listen = ":9811";
              listen_freebind = true;
            }
          ];
        };
        jobs = [
         {
            name = "pointalpha_sink";
            type = "sink";
            root_fs = "ztank/backup";

            serve = {
              type = "tls";
              listen = ":8888";
              ca = "/etc/zrepl/pointalpha.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";

              client_cns = [ "pointalpha" ];
            };
            recv = {
              placeholder = { encryption = "inherit"; };
            };
          }
          {
            name = "sapsrv01_pull";
            type = "pull";
            root_fs = "ztank/sapsrv01";
            interval =  "1h";
            connect = {
              type = "tls";
              address = "sapsrv01.clansap.org:8888";
              ca = "/etc/zrepl/sapsrv01.crt";
              cert = "/etc/zrepl/tank.crt";
              key = "/etc/zrepl/tank.key";

              server_cn = "sapsrv01";
            };
            recv = {
              placeholder = { encryption = "inherit"; };
            };
            pruning = {
              keep_sender = [{
                type = "regex";
                regex = ".*";
              }];
              keep_receiver = [{
                type = "grid";
                grid = "14x1d(keep=all) | 3x30d";
                regex = "^auto_daily.*";
              }];
            };
          }
          {
            name = "tank_data";
            type = "snap";
            filesystems = { "ztank/data<" = true; };
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            pruning = {
              keep = [
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 24x1h | 14x1d | 3x30d | 1x365d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
          {
            name = "tank_replica";
            type = "snap";
            filesystems = { "ztank/replica<" = true; };
            snapshotting = {
              type = "periodic";
              interval = "1h";
              prefix = "zrepl_";
            };
            pruning = {
              keep = [
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 24x1h | 30x1d | 6x30d | 1x365d";
                  regex = "^zrepl_.*";
                }
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
        ];
      };
    };

    nextcloud = {
      enable = true;
      package = pkgs.nextcloud23;
      https = true;
      hostName = "next.tank.pointjig.de";

      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "Sun 14:00:00";
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        dbpassFile = config.age.secrets.nextcloud_db_file.path;
        adminuser = "admin";
        adminpassFile = config.age.secrets.nextcloud_admin_file.path;
        defaultPhoneRegion = "DE";
      };
    };
    postgresql = {
      enable  = true;
      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [
        {
          name = "nextcloud";
          ensurePermissions = {
            "DATABASE nextcloud" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {

        "next.tank.pointjig.de" = {
          forceSSL = true;
          enableACME = true;
        };
      };
    };

    avahi.enable = true;
    avahi.nssmdns = true;

    samba = {
      enable = true;
      openFirewall = true;

      # You will still need to set up the user accounts to begin with:
      # $ sudo smbpasswd -a yourusername

      # This adds to the [global] section:
      extraConfig = ''
        logging = systemd
        min receivefile size = 16384
        use sendfile = true
        aio read size = 16384
        aio write size = 16384
      '';

      shares = {
        homes = {
          browseable = "no";
          writable = "no";
        };
        joerg = {
          path = "/media/joerg";
          writable = "no";
          "valid users" = "shawn";
          public = "no";
          writeable = "yes";
          printable = "no";
          "create mask" = 0700;
          "directory mask" = 0700;
          browseable = "yes";
        };
        ela = {
          path = "/media/daniela";
          writable = "no";
          "valid users" = "ela";
          public = "no";
          writeable = "yes";
          printable = "no";
          "create mask" = 0700;
          "directory mask" = 0700;
          browseable = "yes";
        };
      };
    };

    fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [
        "192.168.11.0/24"
      ];
    };
    vnstat.enable = true;
  };
  security.rtkit.enable = true;
  security.acme = {
      acceptTerms = true;
      defaults.email = "shawn@pointjig.de";
  };


  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;

  sound.enable = false;

  users.users = {
    ela = {
      passwordFile = config.age.secrets.ela_password_file.path;
      isNormalUser = true;
      group = "users";
      uid = 1001;
      shell = pkgs.zsh;
    };
    shawn = {
      extraGroups = [ "nextcloud" ];
    };
  };


  environment = {
    etc.".ztank_key".source = config.age.secrets.ztank_key.path;
    etc."zrepl/tank.key".source = config.age.secrets.zrepl_tank.path;
    etc."zrepl/tank.crt".source = ../../public_certs/zrepl/tank.crt;
    etc."zrepl/pointalpha.crt".source = ../../public_certs/zrepl/pointalpha.crt;
    etc."zrepl/sapsrv01.crt".source = ../../public_certs/zrepl/sapsrv01.crt;
  };

  # remove bloatware (NixOS HTML file)
  documentation.nixos.enable = false;

  system.stateVersion = "21.11";
}
