#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq common-updater-scripts

version="$(curl -sL "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases" | jq 'map(select(.prerelease == false)) | .[0].tag_name' --raw-output)"
update-source-version proton-ge-custom "$version"
