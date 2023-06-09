{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.qtgreet;
  greetdCfg = config.services.greetd;
  settingsFormat = pkgs.formats.ini {};
  greetdSettingsFormat = pkgs.formats.toml {};

  inherit (lib) mkEnableOption mkOption mkIf literalExpression types;
in {
  options.programs.qtgreet = {
    enable = mkEnableOption "Enable QtGreet, a Qt-based greetd greeter";
    package = mkOption {
      type = types.package;
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
    environment.systemPackages = [cfg.package];
    services.greetd.enable = true;
    services.greetd.settings.default_session.command = "${cfg.package}/bin/greetwl --data-path /var/lib/qtgreet";
    environment.etc."greetd/config.toml".source = greetdSettingsFormat.generate "greetd.toml" greetdCfg.settings;
    environment.etc."qtgreet/config.ini".source = settingsFormat.generate "qtgreet.ini" cfg.settings;

    systemd.tmpfiles.rules = let
      user = config.services.greetd.settings.default_session.user;
    in [
      "d /var/lib/qtgreet 0755 greeter ${user} - -"
    ];
  };
}
