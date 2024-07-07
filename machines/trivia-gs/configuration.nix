{
  self',
  config,
  pkgs,
  ...
}:
let
  inherit (config.sops) secrets;
  fPkgs = self'.packages;

  hostname = "mail.trivia-gs.de";
in
{
  sops.secrets = {
    root.neededForUsers = true;
    stalwart-fallback-admin = { };
  };

  networking.firewall = {
    allowedUDPPorts = [ 443 ];
    allowedTCPPorts = [
      80
      443
      # Mail ports for stalwart
      25
      587
      993
      4190
    ];
  };

  systemd.network = {
    enable = true;
    networks = {
      "20-wired" = {
        matchConfig.Name = "enp6s18";
        networkConfig = {
          Address = [
            "134.255.226.117/28"
            "2a05:bec0:1:16::117/64"
          ];
          DNS = "8.8.8.8";
          Gateway = "134.255.226.113";
        };
        routes = [
          {
            Gateway = "2a05:bec0:1:16::1";
            GatewayOnLink = "yes";
          }
        ];
      };
    };
    wait-online.anyInterface = true;
  };

  systemd.services.stalwart-mail = {
    preStart = ''
      mkdir -p /var/lib/stalwart-mail/{queue,reports,db}
    '';
    serviceConfig = {
      User = "stalwart-mail";
      EnvironmentFile = [ secrets.stalwart-fallback-admin.path ];
    };
  };

  services = {
    fstrim.enable = true;
    stalwart-mail = {
      enable = true;
      settings = {
        store.db = {
          type = "rocksdb";
          path = "/var/lib/stalwart-mail/db";
          compression = "lz4";
        };
        storage.blob = "db";

        config.resource = {
          webadmin = "file://${fPkgs.stalwart-webadmin.webadmin}/webadmin.zip";
        };
        authentication.fallback-admin = {
          user = "admin";
          secret = "%{env:FALLBACK_ADMIN_PASSWORD}%";
        };
        lookup.default.hostname = hostname;
        tracer.stdout = {
          level = "trace";
        };
        certificate.default = {
          private-key = "%{file:/var/lib/acme/${hostname}/key.pem}%";
          cert = "%{file:/var/lib/acme/${hostname}/cert.pem}%";
          default = true;
        };
        server = {
          http.use-x-forwarded = true;
          tls.enable = true;
          listener = {
            "smtp" = {
              bind = [ "[::]:25" ];
              protocol = "smtp";
            };
            "submission" = {
              bind = [ "[::]:587" ];
              protocol = "smtp";
            };
            "imaptls" = {
              bind = [ "[::]:993" ];
              protocol = "imap";
              tls.implicit = true;
            };
            "sieve" = {
              bind = [ "[::]:4190" ];
              protocol = "managesieve";
            };
            "http" = {
              bind = [ "127.0.0.1:8080" ];
              protocol = "http";
            };
          };
        };
      };
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      virtualHosts."trivia-gs.de" = {
        enableACME = true;
        forceSSL = true;
        globalRedirect = hostname;
      };
      virtualHosts."${hostname}" = {
        serverName = "${hostname}";
        forceSSL = true;
        enableACME = true;
        http3 = true;
        kTLS = true;
        locations."/" = {
          proxyPass = "http://localhost:8080";
          recommendedProxySettings = true;
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "barannikov.de@gmail.com";
  };

  users = {
    mutableUsers = false;
    users = {
      # So that we can read acme certificate from nginx
      stalwart-mail.extraGroups = [ "nginx" ];
      root = {
        hashedPasswordFile = secrets.root.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
        ];
      };
    };
  };

  shawn8901.server.enable = true;
}
