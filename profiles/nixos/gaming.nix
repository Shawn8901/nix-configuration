{
  self',
  lib,
  ...
}: let
  fPkgs = self'.packages;
in {
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          # Victoria 3
          ncurses
          # Fix fonts for Unity games
          # https://github.com/NixOS/nixpkgs/pull/195521/files
          (pkgs.runCommand "share-fonts" {preferLocalBuild = true;} ''
            mkdir -p "$out/share/fonts"
            font_regexp='.*\.\(ttf\|ttc\|otf\|pcf\|pfa\|pfb\|bdf\)\(\.gz\)?'
            find ${toString [pkgs.liberation_ttf pkgs.dejavu_fonts]} -regex "$font_regexp" \
              -exec ln -sf -t "$out/share/fonts" '{}' \;
          '')
        ];
    };
  };

  programs = {
    steam = {
      enable = true;
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
