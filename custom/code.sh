#!/usr/bin/env bash

[[ -e util.sh ]] && source util.sh || source ../util.sh

if [[ ! -d "/Applications/Visual Studio Code.app" ]]; then
  log please install vscode first
  exit 1
fi

link_file "Library/Application Support/Code/User/"
