{ self', pkgs, ... }: {
  home.packages = [
    self'.packages.keymapp
    pkgs.wally-cli
    pkgs.teamspeak_client
    pkgs.signal-desktop
  ];
}
