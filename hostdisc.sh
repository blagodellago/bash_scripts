#!/bin/bash
# blago
# 05-17-2021
# Discover all hosts on the network

# if no parameter specified, enter interactive mode
if [[ -z $1 ]]; then
	clear
	read -p "Please enter a network (in CIDR notation): " network
elif [[ -n $1 ]]; then
	network=$1
else
	echo "Exiting gracefully."
	exit
fi

if [[ -z $2 ]]; then
	read -p "Specify a network alias: " network_alias
elif [[ -n $2 ]]; then
	network_alias=$2
else
	echo "Exiting gracefully."
	exit
fi

bold=$(tput bold)
normal=$(tput sgr0)

# save the arp table to temp file
arpscan=$(mktemp -t arpscan.XXXXXX)
arpmac=$(mktemp -t arpmac.XXXXXX)
arp-scan $network | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' > $arpmac
cat $arpmac | grep -o -E '[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}' > $arpscan

# save nmap 'List Scan' in temp file with hostname and ip address
lshostname=$(mktemp -t lshostname.XXXXXX)
nmap -sL $network | grep -E '\)$' | cut -d " " -f 5,6 | tr -d '()' > $lshostname

# store only the ip addresses from 'List Scan' in variable
lsip=($(nmap -sL $network | grep -E '\)$' | cut -d " " -f 6 | tr -d '()'))

# define the file that will hold the network targets
network_targets="$HOME/ScanTargets/File_Targets/${network_alias}$(date +%m-%d-%y)"

# delete the file if it already exists for this network on this date
if [[ -s $network_targets ]]; then
	rm $network_targets
else
	:
fi

# check if IP address from nmap 'List Scan' is also present in arp scan. If so, add hostname, ip, & mac to network_hosts.txt file
for ip in ${lsip[*]}; do
	while [[ $(grep "$ip") ]]; do
		nameofhost=$(cat $lshostname | grep -m 1 $ip | cut -d " " -f 1)
		macofhost=$(cat $arpmac | grep -m 1 $ip | grep -o -E '([a-f0-9]{2}:){5}[a-f0-9]{2}')
		echo $nameofhost $ip $macofhost >> $network_targets
		echo "${normal}Adding to target host list: "
		echo "-----${bold}$nameofhost, $ip, $macofhost"
		echo
		echo
	done <$arpscan
done

echo
echo "${normal}The active hosts on the network are: ${bold}"
echo
cat $network_targets
exit
