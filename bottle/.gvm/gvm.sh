#!/usr/bin/env bash

gvm() {
  local default_alias_file="${GVM_PATH}/alias/default"
  if [[ -s $default_alias_file ]]; then
    local default_version="$(cat $default_alias_file)"
    local default_version_bin="${GVM_PATH}/versions/${default_version}/go/bin"
  fi

  "${GVM_PATH}/scripts/gvm" "$@"

  if [[ "$1" == "use" && $? -eq 0 && -s $default_alias_file ]]; then
    local new_version="$(cat $default_alias_file)"

    if [[ $new_version == $default_version ]]; then
      return 0
    fi

    local new_version_bin="${GVM_PATH}/versions/${new_version}/go/bin"

    if [[ ":$PATH:" == *":$default_version_bin:"* ]]; then
      export PATH="${PATH/$default_version_bin/$new_version_bin}"
    else
      export PATH="$new_version_bin:$PATH"
    fi
  fi
}

if [[ -s "${GVM_PATH}/alias/default" ]]; then
  GVM_DEFAULT_VERSION="$(cat "${GVM_PATH}/alias/default")"
  GVM_DEFAULT_VERSION_PATH="${GVM_PATH}/versions/${GVM_DEFAULT_VERSION}/go"

  if [[ -d "$GVM_DEFAULT_VERSION_PATH" ]]; then
    export PATH="${GVM_DEFAULT_VERSION_PATH}/bin:$PATH"
  fi

  unset -v GVM_DEFAULT_VERSION
  unset -v GVM_DEFAULT_VERSION_PATH
fi
