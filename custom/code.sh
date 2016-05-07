#!/usr/bin/env bash

[[ __util__ = 1 ]] || [[ -e util.sh ]] && source util.sh || source ../util.sh

if [[ ! -d "/Applications/Visual Studio Code.app" ]]; then
  open "https://code.visualstudio.com/"
  log please install vscode first
  exit 1
fi

link_file "Library/Application Support/Code/User/"
