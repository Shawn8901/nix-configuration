{ inputs }:

final: prev: {
  remmina = prev.callPackage ./remmina { inherit prev; };
  teamspeak_client = prev.libsForQt5.callPackage ./teamspeak_client { inherit prev; };
  autoadb = prev.callPackage ./autoadb { inherit (inputs.darwin.apple_sdk.frameworks) Security; };
}
