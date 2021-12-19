#!/bin/bash

#
# Powered by VENTO
# https://github.com/VENTO-off/Chrome-Passcode
#

# settings
CHROME_DIR="/home/$(logname)/.config/google-chrome"
CHROME_DATA_DIR="${CHROME_DIR}/Default"

if mountpoint -q $CHROME_DATA_DIR; then
	exit 0
else
	exit 1
fi
