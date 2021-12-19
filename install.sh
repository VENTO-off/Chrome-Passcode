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
ERR="\n${DARK_RED}ERROR:${RED}"
WARN="${DARK_RED}[${RED}!${DARK_RED}]${RED}"
END="${RESET}\n"

# settings
CHROME_DIR="/home/$(logname)/.config/google-chrome"
CHROME_DATA_DIR="${CHROME_DIR}/Default"
CHROME_ENCR_DIR="${CHROME_DIR}/Default.encrypted"
CHROME_TEMP_DIR="${CHROME_DIR}/Default.temp"

function show_menu() {
	clear
	printf "\n"
	printf "${DARK_GREEN}*************************************************************${END}"
	printf "${DARK_GREEN}*\t  ${YELLOW}Chrome Passcode v1.0 (based on gocryptfs)\t    ${DARK_GREEN}*${END}"
	printf "${DARK_GREEN}*\t\t\t\t\t\t\t    *${END}"
	printf "${DARK_GREEN}*\t\t       ${YELLOW}Powered by VENTO\t\t\t    ${DARK_GREEN}*${END}"
	printf "${DARK_GREEN}*\t${YELLOW}https://github.com/VENTO-off/Chrome-Passcode\t    ${DARK_GREEN}*${END}"
	printf "${DARK_GREEN}*************************************************************${END}"
	printf "${DARK_GREEN}* ${DARK_RED}[${RED}1${DARK_RED}] ${GREEN}Install Chrome Passcode\t\t\t\t    ${DARK_GREEN}*${END}"
	printf "${DARK_GREEN}* ${DARK_RED}[${RED}2${DARK_RED}] ${GREEN}Change the password\t\t\t\t    ${DARK_GREEN}*${END}"
	printf "${DARK_GREEN}* ${DARK_RED}[${RED}3${DARK_RED}] ${GREEN}Uninstall and keep Chrome data (need a password)\t    ${DARK_GREEN}*${END}"
	printf "${DARK_GREEN}* ${DARK_RED}[${RED}4${DARK_RED}] ${GREEN}Uninstall and loose Chrome data (without a password)  ${DARK_GREEN}*${END}"
	printf "${DARK_GREEN}*************************************************************${END}\n"
}

function check_root_permissions() {
	if [ `id -u` != "0" ]; then
		printf "${ERR} Please run as root/sudo!${END}"
		exit
	fi
}

function check_google_chrome_installation() {
	if [ ! -d $CHROME_DIR ] || [ ! -f /usr/bin/google-chrome ]; then
	   printf "${ERR} Google Chrome doesn't seem to be installed.${RESET}"
	   printf "${ERR} Install and run Google Chrome first and rerun installation.${END}"
	   exit
	fi
}

function check_chrome_passcode_installation() {
	if [ -d $CHROME_ENCR_DIR ]; then
	   printf "${WARN} Chrome Passcode already installed!${END}"
	   exit
	fi
}

function check_chrome_passcode_require_installation() {
	if [ ! -d $CHROME_ENCR_DIR ]; then
	   printf "${ERR} Chrome Passcode doesn't installed!${RESET}"
	   printf "${ERR} Install Chrome Passcode first and try again.${END}"
	   exit
	fi
}

function check_chrome_running() {
	if pgrep -x "chrome" &> /dev/null; then
		printf "${ERR} Close Google Chrome before this action!${END}"
		exit
	fi
}

function unmount_directory() {
	local directory=$1
	if mount | grep $directory &> /dev/null; then
		umount -f $directory
	fi
}

function input_new_password() {
	printf "\n"
	printf "${WARN} If you will forget the password you can't recover Google Chrome data.${END}"
	printf "\n"
	printf "${YELLOW}Create new password: ${RESET}"
	local password1
	local password2
	read -s password1
	if [ -z $password1 ]; then
		printf "\n"
		printf "${ERR} Password musn't be blank!${END}"
		exit
	fi
	printf "\n"
	printf "${YELLOW}Repeat new password: ${RESET}"
	read -s password2
	if [ $password1 != $password2 ]; then
		printf "\n"
		printf "${ERR} Passwords don't match!${END}"
		exit
	fi
	printf "\n"
	declare -n result=$1
	result=$password1
}

function input_old_password() {
	printf "\n"
	printf "${YELLOW}Enter current password: ${RESET}"
	local current_password
	read -s current_password
	if [ -z $current_password ]; then
		printf "\n"
		printf "${ERR} Password musn't be blank!${END}"
		exit
	fi
	printf "\n"
	declare -n result=$1
	result=$current_password
}

function input_remove_data_agreement() {
	printf "\n"
	printf "${WARN} All the Google Chrome data will be removed! This action cannot be undone.${END}"
	printf "\n"
	printf "${YELLOW}Do you want to continue? [Y/n] ${RESET}"
	local answer
	read answer
	if [[ "${answer,,}" != "y"* ]]; then
		printf "${DARK_RED}Cancelled by user.${END}"
		exit
	fi
}

function install_gocryptfs() {
	printf "${GREEN}Installing gocryptfs... ${RESET}"
	apt-get -y -qq install gocryptfs &>/dev/null
	if [ $? -ne 0 ]; then
		printf "\n"
		printf "${ERR} An error has occurred while installing gocryptfs!${END}"
		exit
	fi
	printf "${GREEN}OK.${END}"
}

function init_gocryptfs() {
	printf "${GREEN}Initializing encrypted filesystem... ${RESET}"
	local password=$1
	if [[ -d $CHROME_DATA_DIR && -n "$(ls -A ${CHROME_DATA_DIR})" ]]; then
		mv $CHROME_DATA_DIR $CHROME_TEMP_DIR
		mkdir $CHROME_DATA_DIR
	fi
	chown $(logname) $CHROME_DATA_DIR
	mkdir $CHROME_ENCR_DIR
	chown $(logname) $CHROME_ENCR_DIR
	echo $password | gocryptfs -init $CHROME_ENCR_DIR &>/dev/null
	if [ $? -ne 0 ]; then
		printf "\n"
		printf "${ERR} An error has occurred while initializing encrypted filesystem!${END}"
		exit
	fi
	chown $(logname) $CHROME_ENCR_DIR/gocryptfs*
	printf "${GREEN}OK.${END}"
}

function install_chrome_passcode() {
	printf "${GREEN}Installing Chrome Passcode... ${RESET}"
	cp -R ./chrome-passcode/ /usr/share/chrome-passcode/
	if [ $? -ne 0 ]; then
		printf "\n"
		printf "${ERR} An error has occurred while installing Chrome Passcode!${END}"
		exit
	fi
	chown -R $(logname) /usr/share/chrome-passcode/
	chmod +x /usr/share/chrome-passcode/*
	printf "${GREEN}OK.${END}"
}

function patch_google_chrome() {
	printf "${GREEN}Patching Google Chrome... ${RESET}"
	sed -i --follow-symlinks "1 r ./google-chrome/patch.txt" /usr/bin/google-chrome
	if [ $? -ne 0 ]; then
		printf "\n"
		printf "${ERR} An error has occurred while patching Google Chrome!${END}"
		exit
	fi
	sed -i --follow-symlinks "1 r ./google-chrome/patch.txt" /usr/bin/google-chrome-stable
	if [ $? -ne 0 ]; then
		printf "\n"
		printf "${ERR} An error has occurred while patching Google Chrome!${END}"
		exit
	fi
	printf "${GREEN}OK.${END}"
}

function change_password() {
	printf "${GREEN}Changing the password for Chrome Passcode... ${RESET}"
	local old_password=$1
	local new_password=$2
	unmount_directory $CHROME_DATA_DIR
	(echo $old_password; echo $new_password) | gocryptfs -passwd $CHROME_ENCR_DIR &>/dev/null
	local exit_code=$?
	if [ $exit_code -ne 0 ]; then
		printf "\n"
		if [ $exit_code -eq 12 ]; then
			printf "${ERR} Current password is incorrect!${END}"
		else
			printf "${ERR} An error has occurred while changing the password!${END}"
		fi
		exit
	fi
	chown $(logname) $CHROME_ENCR_DIR/gocryptfs*
	printf "${GREEN}OK.${END}"
}

function extract_chrome_data() {
	printf "${GREEN}Extracting Google Chrome data... ${RESET}"
	local password=$1
	unmount_directory $CHROME_DATA_DIR
	echo $password | gocryptfs $CHROME_ENCR_DIR $CHROME_DATA_DIR &>/dev/null
	local exit_code=$?
	if [ $exit_code -ne 0 ]; then
		printf "\n"
		if [ $exit_code -eq 12 ]; then
			printf "${ERR} Current password is incorrect!${END}"
		else
			printf "${ERR} An error has occurred while extracting Google Chrome data!${END}"
		fi
		exit
	fi
	rm -rf $CHROME_TEMP_DIR
	mkdir $CHROME_TEMP_DIR
	chown $(logname) $CHROME_TEMP_DIR
	mv $CHROME_DATA_DIR/* $CHROME_TEMP_DIR
	unmount_directory $CHROME_DATA_DIR
	mv $CHROME_TEMP_DIR/* $CHROME_DATA_DIR
	rm -rf $CHROME_TEMP_DIR
	rm -rf $CHROME_ENCR_DIR
	printf "${GREEN}OK.${END}"
}

function remove_chrome_data() {
	printf "${GREEN}Removing Google Chrome data... ${RESET}"
	unmount_directory $CHROME_DATA_DIR
	rm -rf $CHROME_ENCR_DIR
	printf "${GREEN}OK.${END}"
}

function uninstall_chrome_passcode() {
	printf "${GREEN}Uninstalling Chrome Passcode... ${RESET}"
	rm -rf /usr/share/chrome-passcode/
	printf "${GREEN}OK.${END}"
}

function remove_google_chrome_patch() {
	printf "${GREEN}Removing Google Chrome patch... ${RESET}"
	local lines=$(wc -l < ./google-chrome/patch.txt)
	lines=$(($lines + 1))
	sed -i --follow-symlinks "2,${lines}d" /usr/bin/google-chrome
	if [ $? -ne 0 ]; then
		printf "\n"
		printf "${ERR} An error has occurred while removing Google Chrome patch!${END}"
		exit
	fi
	sed -i --follow-symlinks "2,${lines}d" /usr/bin/google-chrome-stable
	if [ $? -ne 0 ]; then
		printf "\n"
		printf "${ERR} An error has occurred while removing Google Chrome patch!${END}"
		exit
	fi
	printf "${GREEN}OK.${END}"
}

check_root_permissions
check_google_chrome_installation
show_menu

printf "${YELLOW}Enter an option from 1-4: ${RESET}"
read opt
if [ -z $opt ]; then
		exit
	else
		case $opt in
		# Install Chrome Passcode
		1) 	check_chrome_passcode_installation
			check_chrome_running
			input_new_password password
			install_gocryptfs
			init_gocryptfs $password
			install_chrome_passcode
			patch_google_chrome
			;;
		# Change the password
		2) 	check_chrome_passcode_require_installation
			check_chrome_running
			input_old_password old_password
			input_new_password new_password
			change_password $old_password $new_password
			;;
		# Uninstall and keep Chrome data
		3) 	check_chrome_passcode_require_installation
			check_chrome_running
			input_old_password old_password
			extract_chrome_data $old_password
			uninstall_chrome_passcode
			remove_google_chrome_patch
			;;
		# Uninstall and loose Chrome data
		4) 	check_chrome_passcode_require_installation
			check_chrome_running
			input_remove_data_agreement
			remove_chrome_data
			uninstall_chrome_passcode
			remove_google_chrome_patch
			;;
		# Invalid input
		*) 	printf "${ERR} Invalid input!${END}"
			;;
		esac
	fi
