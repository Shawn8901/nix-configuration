inputs:
let
  pkgs = inputs.nixpkgs-stable.legacyPackages.x86_64-linux;
  inherit (pkgs.lib) toInt removePrefix filter;
in {
  servePorts = zrepl:
    map (serveEntry: toInt (removePrefix ":" serveEntry.serve.listen))
    (filter (builtins.hasAttr "serve") zrepl.settings.jobs);

  monitoringPorts = zrepl:
    map (monitoringEntry: toInt (removePrefix ":" monitoringEntry.listen))
    (filter (builtins.hasAttr "listen") zrepl.settings.global.monitoring);
}
