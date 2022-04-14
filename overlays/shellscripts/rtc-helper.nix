{ writeShellScriptBin, pkgs }:

writeShellScriptBin "rtc-helper" ''
  ${pkgs.util-linux}/bin/rtcwake -m no -t $(${pkgs.coreutils-full}/bin/date +%s -d 'tomorrow 12:00')
''
