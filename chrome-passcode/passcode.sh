#!/bin/bash

#
# Powered by VENTO
# https://github.com/VENTO-off/Chrome-Passcode
#

# colors
RESET=`echo "\033[m"`
DARK_RED=`echo "\033[1;31m"`
DARK_GREEN=`echo "\033[1;32m"`
RED=`echo "\033[1;91m"`
GREEN=`echo "\033[1;92m"`
YELLOW=`echo "\033[1;93m"`

# message templates
END="${RESET}\n"

# settings
CHROME_DIR="/home/$(logname)/.config/google-chrome"
CHROME_DATA_DIR="${CHROME_DIR}/Default"
CHROME_ENCR_DIR="${CHROME_DIR}/Default.encrypted"
CHROME_TEMP_DIR="${CHROME_DIR}/Default.temp"

function show_splash() {
	clear
	printf "\n"
	printf "${YELLOW}        ██████╗██╗  ██╗██████╗  ██████╗ ███╗   ███╗███████╗        ${END}"
	printf "${YELLOW}       ██╔════╝██║  ██║██╔══██╗██╔═══██╗████╗ ████║██╔════╝        ${END}"
	printf "${YELLOW}       ██║     ███████║██████╔╝██║   ██║██╔████╔██║█████╗          ${END}"
	printf "${YELLOW}       ██║     ██╔══██║██╔══██╗██║   ██║██║╚██╔╝██║██╔══╝          ${END}"
	printf "${YELLOW}       ╚██████╗██║  ██║██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗        ${END}"
	printf "${YELLOW}        ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝        ${END}"
	printf "\n"
	printf "${YELLOW} ██████╗  █████╗ ███████╗███████╗ ██████╗ ██████╗ ██████╗ ███████╗ ${END}"
	printf "${YELLOW} ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔════╝ ${END}"
	printf "${YELLOW} ██████╔╝███████║███████╗███████╗██║     ██║   ██║██║  ██║█████╗   ${END}"
	printf "${YELLOW} ██╔═══╝ ██╔══██║╚════██║╚════██║██║     ██║   ██║██║  ██║██╔══╝   ${END}"
	printf "${YELLOW} ██║     ██║  ██║███████║███████║╚██████╗╚██████╔╝██████╔╝███████╗ ${END}"
	printf "${YELLOW} ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝ ${END}"
}

function require_login() {
	printf "\n"
	printf "${YELLOW}=====================${RED} -=[ ENTER PASSWORD ]=- ${YELLOW}=====================${END}"
}

function success_login() {
	printf "\n"
	printf "\n"
	printf "${DARK_GREEN}\t\t       ++++++++++++++++++++${END}"
	printf "${DARK_GREEN}\t\t       +${GREEN} LOGIN SUCCESSFUL ${DARK_GREEN}+${END}"
	printf "${DARK_GREEN}\t\t       ++++++++++++++++++++${END}"
}

function bad_login() {
	printf "\n"
	printf "\n"
	printf "${DARK_RED}\t\t      ++++++++++++++++++++++${END}"
	printf "${DARK_RED}\t\t      +${RED} PASSWORD INCORRECT ${DARK_RED}+${END}"
	printf "${DARK_RED}\t\t      ++++++++++++++++++++++${END}"
}

function unexpected_error() {
	printf "\n"
	printf "\n"
	printf "${DARK_RED}\t\t  +++++++++++++++++++++++++++++++${END}"
	printf "${DARK_RED}\t\t  +${RED} AN UNEXPECTED ERROR OCCURED ${DARK_RED}+${END}"
	printf "${DARK_RED}\t\t  +++++++++++++++++++++++++++++++${END}"
}

function remove_chrome_data() {
	rm -rf $CHROME_DATA_DIR/*
}

function check_temp_data() {
	if [[ -d $CHROME_TEMP_DIR && -n "$(ls -A ${CHROME_TEMP_DIR})" ]]; then
		mv $CHROME_TEMP_DIR/* $CHROME_DATA_DIR
		rm -rf $CHROME_TEMP_DIR
	fi
}

if ! mountpoint -q $CHROME_DATA_DIR; then
	show_splash ; require_login
	read -s password
	remove_chrome_data
	echo $password | gocryptfs $CHROME_ENCR_DIR $CHROME_DATA_DIR &>/dev/null
	exit_code=$?
	if [ $exit_code -eq 0 ]; then
		show_splash ; success_login
		check_temp_data
		sleep 1
		exit 0
	elif [ $exit_code -eq 12 ]; then
		show_splash ; bad_login
		sleep 1
		exit 1
	else 
		show_splash ; unexpected_error
		sleep 1
		exit 1
	fi
fi
