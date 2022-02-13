{ prev, vte }:

prev.remmina.overrideAttrs (oldAttrs: rec {
  cmakeFlags = oldAttrs.cmakeFlags ++ [
    "-DWITH_VTE=ON"
  ];
  buildInputs = oldAttrs.buildInputs ++ [
    vte
  ];
})

