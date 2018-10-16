#!/bin/bash
folder="${1}"
if [ "${folder}" == "" ]; then
    echo "MUST provide a target folder"
    exit 1
fi


images=("boot" "cache" "persist" "recovery" "system" "userdata")

pushd "${folder}"
    echo "Entering boot loader"
    adb reboot bootloader

    for image in "${images[@]}"; do
        if [ ! -e "${image}.img" ]; then
            continue;
        fi

        echo "Flashing ${image}..."
        fastboot flash "${image}" "${image}.img"
    done

    echo "Rebooting"
    fastboot reboot
popd
