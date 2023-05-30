{
  pkgs,
  lib,
  writeShellScriptBin,
  backupPath ? "/media/backup/",
  mountPoint ? "/media/backup-usb",
}:
writeShellScriptBin "backup-usb" ''
  BACKUP_SOURCE="${backupPath}"
  BACKUP_DEVICE="/dev/$1"
  MOUNT_POINT="${mountPoint}"

  if [ ! -d "$MOUNT_POINT" ]; then
    ${pkgs.coreutils-full}/bin/mkdir "$MOUNT_POINT";
  fi
  echo "Mount $BACKUP_DEVICE"
  ${pkgs.util-linux}/bin/mount -o uid=ela,gid=users,umask=0022 -t auto "$BACKUP_DEVICE" "$MOUNT_POINT"

  echo "Starting RSYNC"
  ${lib.getExe pkgs.rsync} -Pauvi "$BACKUP_SOURCE" "$MOUNT_POINT"
  ${pkgs.coreutils-full}/bin/sync

  echo "Unmount $BACKUP_DEVICE"
  ${pkgs.udisks2}/bin/udisksctl unmount -b ''${BACKUP_DEVICE}

  sleep 1
  ${lib.getExe pkgs.beep}

  echo "Poweroff device"
  ${pkgs.udisks2}/bin/udisksctl power-off -b ''${BACKUP_DEVICE//[[:digit:]]}

  ${lib.getExe pkgs.beep}
''
