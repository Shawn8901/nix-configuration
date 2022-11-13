#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq common-updater-scripts

version="$(curl -sL "https://api.github.com/repos/marzzzello/pytr/tags" | jq '.[0].name' --raw-output)"
update-source-version pytr "$version"
