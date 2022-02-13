{ inputs }:

final: prev: {
  remmina =  prev.callPackage ./remmina { inherit prev; };
  autoadb =  prev.callPackage ./autoadb {  inherit (inputs.darwin.apple_sdk.frameworks) Security; };
  ts3overlay = prev.libsForQt512.callPackage ./ts3client {};
}
