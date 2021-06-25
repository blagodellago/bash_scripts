#!/bin/bash
# blago
# 05-19-21

# a bash script template builder
if [[ -z "$1" ]]; then
	echo
	read -p "Enter a script name: " scriptname
	echo
else
	scriptname=$1
fi

if [[ -z "$2" ]]; then
	echo
	read -p "Enter a script description: " description
	echo
else
	description=$2
fi

scriptpath="$HOME/bash_scripts/$scriptname"
exec 3>>$scriptpath
echo "#!/bin/bash" >&3
echo "# $(whoami)" >&3
echo "# $(date +%m-%d-%y)" >&3
echo >&3
if [[ -n $description ]]; then
	printf '#%.0s' $(seq -2 $(echo $description | wc -c)) >&3
	echo >&3
	echo "# $description #" >&3
	printf '#%.0s' $(seq -2 $(echo $description | wc -c)) >&3
else
	if [[ -e $scriptpath ]]; then
		rm $scriptpath
		exit
	else
		exit
	fi
fi

echo >&3

chmod u+x $scriptpath
sublime $scriptpath
