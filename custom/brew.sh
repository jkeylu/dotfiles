#!/usr/bin/env bash

if command -v brew >/dev/null 2>&1; then
  echo "brew already installed"
  exit 0
fi

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
