{ config, pkgs, inputs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.shawn = {
      home.stateVersion = "22.05";
      imports = [ ../home/git.nix ];
      programs.zsh = {
        enable = true;
      };
    };
  };
}
