{writeShellScriptBin}:
writeShellScriptBin "update-packages" ''
  find . -name 'update.sh' -exec nix-shell -p curl jq common-updater-scripts --command {} \;
''
