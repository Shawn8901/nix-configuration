inputs: {
  locale = import ./locale.nix inputs;
  nix-config = import ./nix.nix inputs;
  build-tools = import ./build-tools.nix inputs;
  user-config = import ./user-config.nix inputs;
  shutdown-wakeup = import ./shutdown-wakeup.nix inputs;
  usb-backup = import ./usb-backup.nix inputs;
  nextcloud-backup = import ./nextcloud-backup.nix inputs;
  wayland = import ./wayland.nix inputs;
}
