#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq common-updater-scripts

version="$(curl -sL "https://api.github.com/repos/Return-To-The-Roots/s25client/releases" | jq 'map(select(.prerelease == false)) | .[0].tag_name' --raw-output)"
update-source-version s25rttr "$version"
