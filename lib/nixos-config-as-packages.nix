{ self, ... }@inputs:
let
  pkgs = self.sPkgs;

  inherit (pkgs.lib) genAttrs mapAttrs';

  hostNames = __attrNames self.nixosConfigurations;
  attrHostNames = genAttrs hostNames (name: "machines/${name}");
  configs = mapAttrs'
    (name: pname: {
      name = pname;
      value = self.nixosConfigurations.${name}.config.system.build.toplevel;
    })
    attrHostNames;
in
{ x86_64-linux = configs; }
