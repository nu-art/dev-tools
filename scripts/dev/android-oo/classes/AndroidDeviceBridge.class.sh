#!/bin/bash

AndroidDeviceBridge() {
  declare -a devices

  _isDeviceRegistered() {
    local serial=${1}

    for device in ${devices[@]}; do
      [[ "$("${device}.serial")" == "${serial}" ]] && echo true && return
    done
  }

  _detectDevices() {
    local output=$(adb devices | grep -E "[A-Za-z0-9.:].*" )
    while IFS= read -r deviceLine; do
      local deviceRef=device${#devices[@]}
      lcoal serial="$(echo "${deviceLine}" | sed -E "s/(.*) .*/\1/")"
      [[ $(this.isDeviceRegistered "${serial}") ]] && continue

      new AndroidDevice "${deviceRef}"
      "${deviceRef}.serial" = "${serial}"
      devices+=("${deviceRef}")
    done <<< "$output"
  }
}
