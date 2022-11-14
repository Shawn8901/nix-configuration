{ self, config, pkgs, lib, inputs, ... }:
let
  secrets = config.age.secrets;
in
{
  age.secrets = {
    ffm_nextcloud_db_file = {
      file = ../../secrets/ffm_nextcloud_db.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    ffm_root_password_file = {
      file = ../../secrets/ffm_root_password.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
  };

  networking = {
    firewall =
      {
        allowedUDPPorts = [ 443 ];
        allowedUDPPortRanges = [ ];
        allowedTCPPorts = [ 80 443 ];
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
          matchConfig.Name = "enp6s18";
          networkConfig.Address = [ "134.255.226.117/28" "2a05:bec0:1:16::117/64" ];
          networkConfig.DNS = "8.8.8.8";
          networkConfig.Gateway = "134.255.226.113";
          routes = [{
            routeConfig = {
              Gateway = "2a05:bec0:1:16::1";
              GatewayOnLink = "yes";
            };
          }];
        };
      };
      };
  };

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };
    resolved.enable = true;
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud25;
      https = true;
      hostName = "next2.clansap.org";
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "Sun 14:00:00";
      phpOptions."opcache.interned_strings_buffer" = "16";
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        dbpassFile = secrets.ffm_nextcloud_db_file.path;
        adminuser = "admin";
        adminpassFile = secrets.ffm_root_password_file.path;
        defaultPhoneRegion = "DE";
      };
      caching.apcu = true;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      ensureDatabases = [
        "${config.services.nextcloud.config.dbname}"
      ];
      ensureUsers = [
        {
          name = "${config.services.nextcloud.config.dbuser}";
          ensurePermissions = {
            "DATABASE ${config.services.nextcloud.config.dbname}" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${config.services.nextcloud.hostName}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
        };
      };
    };
    fail2ban = {
      enable = true;
      maxretry = 5;
    };
    vnstat.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=500M
      SystemMaxFileSize=100M
    '';
    acpid.enable = true;
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "info@clansap.org";
  };
  security.auditd.enable = false;
  security.audit.enable = false;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;

  env.auto-upgrade.enable = true;
  env.user-config.enable = false;

  users.mutableUsers = false;
  users.users.root = {
    passwordFile = secrets.ffm_root_password_file.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
    ];
  };

  environment.systemPackages = [
      (pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        # XXX replace `<new version>` with the psqlSchema here
        export NEWDATA="/var/lib/postgresql/14"

        # XXX specify the postgresql package you'd like to upgrade to
        export NEWBIN="${pkgs.postgresql_14}/bin"

        export OLDDATA="${config.services.postgresql.dataDir}"
        export OLDBIN="${config.services.postgresql.package}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

        sudo -u postgres $NEWBIN/pg_upgrade \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir $OLDBIN --new-bindir $NEWBIN \
          "$@"
      '')
  ];
}
