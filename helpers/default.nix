{ lib, ... }:

{
  zreplServePorts = zrepl:
    map (serveEntry: lib.toInt (lib.removePrefix ":" serveEntry.serve.listen)) (lib.filter (entry: builtins.hasAttr "serve" entry) zrepl.settings.jobs);
  zreplMonitoringPorts = zrepl:
    map (monitoringEntry: lib.toInt (lib.removePrefix ":" monitoringEntry.listen)) zrepl.settings.global.monitoring;
}
