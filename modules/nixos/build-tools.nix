{
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs.hostPlatform) system;
in {
  environment.systemPackages = with pkgs;
    [
      git
      htop
      nano
      vim
    ]
    ++ [inputs.agenix.packages.${system}.agenix];
}
