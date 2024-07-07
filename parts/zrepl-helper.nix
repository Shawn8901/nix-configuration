{ lib, ... }:
let
  inherit (lib)
    mkOption
    types
    toInt
    removePrefix
    filter
    ;
in
{
  options = {
    shawn8901.zrepl = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
    };
  };

  config.shawn8901.zrepl.servePorts =
    zrepl:
    map (serveEntry: toInt (removePrefix ":" serveEntry.serve.listen)) (
      filter (builtins.hasAttr "serve") zrepl.settings.jobs
    );

  config.shawn8901.zrepl.monitoringPorts =
    zrepl:
    builtins.head (
      map (monitoringEntry: toInt (removePrefix ":" monitoringEntry.listen)) (
        filter (builtins.hasAttr "listen") zrepl.settings.global.monitoring
      )
    );
}
