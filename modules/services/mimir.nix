{ config, lib, pkgs, ... }:
let
  cfg = config.services.mimir;
in
with lib;
{
  options = {
    services.mimir = {
      enable = mkEnableOption "Mimir service";
    };
  };

  config = mkIf cfg.enable {

    users.users.mimir = {
      group = config.users.groups.mimir.name;
      isSystemUser = true;
      createHome = false;
    };
    users.groups.mimir = { };

    systemd.tmpfiles.rules = [
      "d '/var/mimir/secrets' 0700 ${config.users.users.mimir.name} ${config.users.users.mimir.group} - -"
    ];

    systemd.services.mimir =
      let
        djangoEnv = pkgs.python3.withPackages (ps: with ps; [
          daphne
          django
        ]);
      in
      {
        description = "Mimir running via daphne";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          PYTHONPATH = "/var/mimir/";
        };
        serviceConfig = {
          WorkingDirectory = "/var/mimir/mimir/";
          ExecStartPre =
            let
              mimirPermsScript = pkgs.writeShellScript "mimir-perms" ''
                set -eu -o pipefail
                echo "Setting permissions"
                chown -R ${config.users.users.mimir.name}:${config.users.users.mimir.group} /var/mimir/mimir
              '';
              managepyScript = pkgs.writeShellScript "mimir-managepy" ''
                set -eu -o pipefail
                echo "Running manage.py"
                ${djangoEnv}/bin/python manage.py migrate;
                ${djangoEnv}/bin/python manage.py collectstatic --no-input;
              '';
            in
            ''
              +${mimirPermsScript} ; ${managepyScript}
            '';
          ExecStart = ''${djangoEnv}/bin/daphne -u /var/mimir/mimir.sock asgi:application
          '';
          Restart = "always";
          RestartSec = "10s";
          User = config.users.users.mimir.name;
        };
        unitConfig.StartLimitIntervalSec = 0;
      };

    services.nginx = {
      clientMaxBodySize = "10M";
      recommendedGzipSettings = true;
      recommendedTlsSettings = false;
      virtualHosts = {
        "mimir.pointjig.local" = {
          enableACME = false;
          forceSSL = false;
          locations = {
            "/" = {
              proxyPass = "http://unix:/var/mimir/mimir.sock";
            };
            "/static/" = {
              alias = "/var/mimir/static/";
            };
            "/media/" = {
              alias = "/var/mimir/media/";
            };
            "/public/" = {
              alias = "/var/mimir/public/";
            };
            "/.well-known/" = {
              alias = "/var/mimir/.well-known/";
            };
            "/private/" = {
              alias = "/var/mimir/private/";
              extraConfig = "internal;";
            };
          };
          extraConfig = ''
            location = /favicon.ico {
              alias /home/mimir/static/spy.png;
            }
          '';
        };
      };
    };
  };
}
