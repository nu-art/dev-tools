#!/bin/bash

adb reboot bootloader
fastboot oem select-display-panel hdmi
fastboot reboot