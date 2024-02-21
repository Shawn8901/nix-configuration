# Be aware that this does not work its a WIP!

{ self', config, lib, pkgs, ... }:
let
  cfg = config.programs.qtgreet;
  greetdCfg = config.services.greetd;
  settingsFormat = pkgs.formats.ini { };
  greetdSettingsFormat = pkgs.formats.toml { };

  inherit (lib) mkEnableOption mkOption mkIf literalExpression types;

  wrapper = pkgs.writeShellScriptBin "qtgreet-wrapper" ''

    ${builtins.concatStringsSep "\n" exportVariables}

    exec ${cfg.package}/bin/greetwl --data-path /var/lib/qtgreet
  '';

  exportVariables = builtins.attrValues
    (builtins.mapAttrs (n: v: "export ${n}=${v}") cfg.envVars);

in {
  options.programs.qtgreet = {
    enable = mkEnableOption "Enable QtGreet, a Qt-based greetd greeter";
    package = mkOption {
      type = types.package;
      default = self'.packages.qtgreet;
      description = "QTgreet package to be used";
    };
    envVars = lib.mkOption {
      type = types.attrs;
      default = { };
      description = lib.mdDoc ''
        Environment variables set by the wrapper.
      '';
    };
    settings = mkOption {
      type = settingsFormat.type;
      default = {
        General = {
          Backend = "GreetD";
          Theme = "default";
          BlurBackground = "true";
        };
        Overrides = {
          Background = "Theme";
          BaseColor = "Theme";
          TextColor = "Theme";
        };
      };
      defaultText = literalExpression ''
        {
          General = {
            Backend = "GreetD";
            Theme = "default";
            BlurBackground = "true";
          };
          Overrides = {
            Background = "Theme";
            BaseColor = "Theme";
            TextColor = "Theme";
          };
        }
      '';
      description = "QtGreet configuration as a Nix attribute set";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.greetd.enable = true;
    services.greetd.settings.default_session.command = lib.getExe wrapper;
    environment.etc."qtgreet/config.ini".source =
      settingsFormat.generate "qtgreet.ini" cfg.settings;

    systemd.tmpfiles.rules =
      let user = config.services.greetd.settings.default_session.user;
      in [ "d /var/lib/qtgreet 0755 greeter ${user} - -" ];
  };
}
