final: prev: {
  remmina = prev.callPackage ./remmina { inherit prev; };
  jameica = prev.callPackage ./jameica { inherit prev; };
  autoadb = prev.callPackage ./autoadb { inherit (prev.darwin.apple_sdk.frameworks) Security; };
}
