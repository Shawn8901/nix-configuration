{ self, nixpkgs, ... }:
let
  inherit (nixpkgs.lib) genAttrs mapAttrs';

  hostNames = __attrNames self.nixosConfigurations;
  attrHostNames = genAttrs hostNames (name: "machines/${name}");
  configs = mapAttrs'
    (name: pname: {
      name = pname;
      value = self.nixosConfigurations.${name}.config.system.build.toplevel;
    })
    attrHostNames;
in
{ inherit configs; }
