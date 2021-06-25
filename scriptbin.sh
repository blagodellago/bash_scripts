#!/bin/bash
# blago
# 05-24-21

bold=$(tput bold)
normal=$(tput sgr0)

# Creates an executable binary for bash scripts located in /usr/local/bin

if [[ -n $1 ]]; then
	scriptfile=$1
else
	read -p "Enter the name of the script file: " scriptfile
fi

scriptbin=$(echo $scriptfile | grep -o '[^/]*$' | cut -d "." -f 1)

if [ -e /usr/local/bin/$scriptbin ]; then
	echo
	echo "Symlink already exists for $scriptbin."
	echo
	echo "######################################################################################################"
	echo
	ls -la /usr/local/bin
	echo
	echo "######################################################################################################"
	echo
	echo "Not creating additional symlink."
	echo "Exiting."
	echo
	exit
else
	ln -s $HOME/bash_scripts/$scriptfile /usr/local/bin/$scriptbin
fi

ls -la /usr/local/bin
