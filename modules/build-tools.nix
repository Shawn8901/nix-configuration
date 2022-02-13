{ config, pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    nvd
    git
  ];

}
