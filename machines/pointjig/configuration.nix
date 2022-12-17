{ config, inputs, pkgs, ... }:
let
  secrets = config.age.secrets;
  inherit (inputs) stfc-bot mimir;
in
{
  # FIXME: Remove with 23.05
  disabledModules = [ "services/monitoring/prometheus/default.nix" ];
  imports = [ stfc-bot.nixosModule mimir.nixosModule ../../modules/nixos/overriden/prometheus.nix ];

  age.secrets = {
    sms-shawn-passwd = {
      file = ../../secrets/sms-shawn-passwd.age;
      owner = "stfc-bot";
      group = "stfc-bot";
    };
    stfc-env = {
      file = ../../secrets/stfc-env.age;
      owner = "stfc-bot";
      group = "stfc-bot";
    };
    mimir-env = {
      file = ../../secrets/mimir-env.age;
      owner = "mimir";
      group = "mimir";
    };
    prometheus_web_config = {
      file = ../../secrets/web_config_public_prometheus.age;
      owner = "prometheus";
      group = "prometheus";
    };
  };

  nix.gc.options = "--delete-older-than 3d";

  networking = {
    firewall = {
      allowedUDPPorts = [ 443 ];
      allowedUDPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 ];
      allowedTCPPortRanges = [ ];
      logRefusedConnections = false;
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
          networkConfig.Address =
            [ "134.255.226.114/28" "2a05:bec0:1:16::114/64" ];
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
      wait-online.anyInterface = true;
    };
  };

  services = {
    xserver.enable = false;
    qemuGuest.enable = true;
    fstrim.enable = true;
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };
    resolved.enable = true;
    fail2ban = {
      enable = true;
      maxretry = 5;
    };
    vnstat.enable = true;
    journald.extraConfig = ''
      SystemMaxUse=100M
      SystemMaxFileSize=50M
    '';
    acpid.enable = true;
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      settings = {
        max_connections = 200;
      };
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "${config.services.stne-mimir.domain}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
        };
        "status.${config.networking.hostName}.de" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;

          locations."/" = {
            proxyPass = "http://localhost:9001";
          };
        };
      };
    };
    prometheus =
      let
        labels = { machine = "${config.networking.hostName}"; };
        nodePort = config.services.prometheus.exporters.node.port;
        postgresPort = config.services.prometheus.exporters.postgres.port;
      in
      {
        enable = true;
        port = 9001;
        retentionTime = "30d";
        globalConfig = {
          external_labels = labels;
        };
        webConfigFile = secrets.prometheus_web_config.path;
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [{ targets = [ "localhost:${toString nodePort}" ]; inherit labels; }];
          }
          {
            job_name = "postgres";
            static_configs = [{ targets = [ "localhost:${toString postgresPort}" ]; inherit labels; }];
          }
        ];
        exporters = {
          node = {
            enable = true;
            listenAddress = "localhost";
            port = 9101;
            enabledCollectors = [ "systemd" ];
          };
          postgres = {
            enable = true;
            listenAddress = "127.0.0.1";
            port = 9187;
            runAsLocalSuperUser = true;
          };
        };
      };
    stfc-bot = {
      enable = true;
      package = inputs.stfc-bot.packages.x86_64-linux.default;
      envFile = config.age.secrets.stfc-env.path;
    };
    stne-mimir = {
      enable = true;
      domain = "mimir.pointjig.de";
      clientPackage = inputs.mimir-client.packages.x86_64-linux.default;
      package = inputs.mimir.packages.x86_64-linux.default;
      envFile = config.age.secrets.mimir-env.path;
      unixSocket = "/run/mimir-backend/mimir-backend.sock";
    };
  };

  mailserver = {
    enable = true;
    fqdn = "mail.pointjig.de";
    domains = [ "pointjig.de" ];
    certificateScheme = 3;
    loginAccounts = {
      "shawn@pointjig.de" = {
        hashedPasswordFile = "${secrets.sms-shawn-passwd.path}";
        aliases = [
          "aktienfinder@pointjig.de"
          "alphavps@pointjig.de"
          "caseking@pointjig.de"
          "check24@pointjig.de"
          "codeberg@pointjig.de"
          "dropbox@pointjig.de"
          "epic@pointjig.de"
          "estateguru@pointjig.de"
          "flexispot@pointjig.de"
          "fritz@pointjig.de"
          "geizhals@pointjig.de"
          "git@pointjig.de"
          "megaprimus@pointjig.de"
          "mindfactory@pointjig.de"
          "ninjatrader@pointjig.de"
          "parqet@pointjig.de"
          "planetside@pointjig.de"
          "smite@pointjig.de"
          "spocks@pointjig.de"
          "spotify@pointjig.de"
          "steam@pointjig.de"
          "stfc@pointjig.de"
          "stne@pointjig.de"
          "sto@pointjig.de"
          "supremegamers@pointjig.de"
          "unity@pointjig.de"
          "zsa@pointjig.de"
        ];
      };
      "dorman@pointjig.de" = {
        hashedPasswordFile = "${secrets.sms-shawn-passwd.path}";
        aliases = [
          "ninjatrader@pointjig.de"
        ];
      };
    };
  };

  security.auditd.enable = false;
  security.audit.enable = false;
  security.acme = {
    acceptTerms = true;
    defaults.email = "shawn@pointjig.de";
  };
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  sound.enable = false;
  env.auto-upgrade.enable = true;
  env.user-config.enable = true;

  environment.noXlibs = true;
  environment.systemPackages = [
    (pkgs.writeScriptBin "upgrade-pg-cluster" ''
      set -eux
      # XXX it's perhaps advisable to stop all services that depend on postgresql
      systemctl stop postgresql

      # XXX replace `<new version>` with the psqlSchema here
      export NEWDATA="/var/lib/postgresql/${pkgs.postgresql_15.psqlSchema}"

      # XXX specify the postgresql package you'd like to upgrade to
      export NEWBIN="${pkgs.postgresql_15}/bin"

      export OLDDATA="/var/lib/postgresql/${pkgs.postgresql_14.psqlSchema}"
      export OLDBIN="${pkgs.postgresql_14}/bin"

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
