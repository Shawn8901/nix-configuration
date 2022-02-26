{ inputs }:

final: prev: {
  remmina =  prev.callPackage ./remmina { inherit prev; };
  autoadb =  prev.callPackage ./autoadb {  inherit (inputs.darwin.apple_sdk.frameworks) Security; };
  gnome-shell-extension-caffine =  prev.callPackage ./gnomeextensions/caffine.nix { };
  gnome-shell-extension-alphabetical-app-grid =  prev.callPackage ./gnomeextensions/alphabetical-app-grid.nix { };
  ts3overlay = prev.libsForQt512.callPackage ./ts3client {};
}
