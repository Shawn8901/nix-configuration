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

  systemd.network = {
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

  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  services = {
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
