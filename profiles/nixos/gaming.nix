{
  self',
  config,
  lib,
  pkgs,
  ...
}: let
  fPkgs = self'.packages;
in {
  programs = {
    steam = {
      enable = true;
      package = pkgs.steam-small.override {
        extraEnv = {
          AMD_VULKAN_ICD = config.environment.sessionVariables.AMD_VULKAN_ICD;
        };
        extraLibraries = p: [
          # Fix Unity Fonts
          (pkgs.runCommand "share-fonts" {preferLocalBuild = true;} ''
            mkdir -p "$out/share/fonts"
            font_regexp='.*\.\(ttf\|ttc\|otf\|pcf\|pfa\|pfb\|bdf\)\(\.gz\)?'
            find ${toString [pkgs.liberation_ttf pkgs.dejavu_fonts]} -regex "$font_regexp" \
              -exec ln -sf -t "$out/share/fonts" '{}' \;
          '')
          p.getent
        ];
      };
      extraCompatPackages = [fPkgs.proton-ge-custom];
    };
    haguichi.enable = false;
  };

  # networking = {
  #   firewall = {
  #     # Stronghold
  #     allowedUDPPortRanges = [
  #       {
  #         from = 2300;
  #         to = 2400;
  #       }
  #     ];
  #     allowedTCPPorts = [47624];
  #     allowedTCPPortRanges = [
  #       {
  #         from = 2300;
  #         to = 2400;
  #       }
  #     ];
  #   };
  # };
}
