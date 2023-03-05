{
  locale = import ./locale.nix;
  nix-config = import ./nix.nix;
  build-tools = import ./build-tools.nix;
  user-config = import ./user-config.nix;
  shutdown-wakeup = import ./shutdown-wakeup.nix;
  usb-backup = import ./usb-backup.nix;
  nextcloud-backup = import ./nextcloud-backup.nix;
  auto-upgrade = import ./auto-upgrade.nix;
  asus-touchpad-numpad = import ./asus-touchpad-numpad.nix;
  pipewire-rt = import ./pipewire-rt.nix;
}
