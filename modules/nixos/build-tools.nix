{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.hostPlatform.system;
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
