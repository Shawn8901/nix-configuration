{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.steam;

  steam = pkgs.steam.override {
    extraLibraries = pkgs: with config.hardware.opengl;
      if pkgs.hostPlatform.is64bit
      then [ package ] ++ extraPackages
      else [ package32 ] ++ extraPackages32;
  };
in
{
  options.programs.steam = {
    enable = mkEnableOption (lib.mdDoc "steam");

    remotePlay.openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Open ports in the firewall for Steam Remote Play.
      '';
    };

    dedicatedServer.openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Open ports in the firewall for Source Dedicated Server.
      '';
    };

    extraCompatPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      defaultText = literalExpression "[]";
      example = literalExpression ''
        with pkgs; [
          luxtorpeda
          proton-ge
        ]
      '';
      description = lib.mdDoc ''
        Extra packages to be used as compatibility tools for Steam on Linux. Packages will be included
        in the `STEAM_EXTRA_COMPAT_TOOLS_PATHS` environmental variable. For more information see
        <https://github.com/ValveSoftware/steam-for-linux/issues/6310">.
      '';
    };
  };

  config = mkIf cfg.enable {
    hardware.opengl = {
      # this fixes the "glXChooseVisual failed" bug, context: https://github.com/NixOS/nixpkgs/issues/47932
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    # optionally enable 32bit pulseaudio support if pulseaudio is enabled
    hardware.pulseaudio.support32Bit = config.hardware.pulseaudio.enable;

    hardware.steam-hardware.enable = true;

    networking.firewall = lib.mkMerge [
      (mkIf cfg.remotePlay.openFirewall {
        allowedTCPPorts = [ 27036 ];
        allowedUDPPortRanges = [{ from = 27031; to = 27036; }];
      })

      (mkIf cfg.dedicatedServer.openFirewall {
        allowedTCPPorts = [ 27015 ]; # SRCDS Rcon port
        allowedUDPPorts = [ 27015 ]; # Gameplay traffic
      })
    ];

    # Append the extra compatibility packages to whatever else the env variable was populated with.
    # For more information see https://github.com/ValveSoftware/steam-for-linux/issues/6310.
    environment.sessionVariables = mkIf (cfg.extraCompatPackages != [ ]) {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = concatStringsSep ":" cfg.extraCompatPackages;
    };

    environment.systemPackages = [ steam steam.run ] ++ cfg.extraCompatPackages;
  };

  meta.maintainers = with maintainers; [ mkg20001 ];
}
