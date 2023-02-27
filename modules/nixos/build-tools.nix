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
      nix-output-monitor
    ]
    ++ [inputs.agenix.packages.${system}.agenix];
}
