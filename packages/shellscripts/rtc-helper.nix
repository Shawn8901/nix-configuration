{
  writeShellScriptBin,
  pkgs,
  wakeupTime ? "13:00:00",
}:
writeShellScriptBin "rtc-helper" ''
  ${pkgs.util-linux}/bin/rtcwake -m no -t $(${pkgs.coreutils-full}/bin/date +%s -d 'tomorrow ${wakeupTime}')
''
