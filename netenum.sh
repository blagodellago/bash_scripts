#!/bin/bash
#### SCAN FOR OPEN PORTS, INTENSE SCAN EACH OPEN PORT, & LAUNCH NIKTO (IF HTTP/HTTPS) 

# calculate execution time upon exit
start=$(date +%s)

# create bold & normal font pointers
bold=$(tput bold)
normal=$(tput sgr0)
today=$(date +%m-%d-%y)

# If a scan directory for target host does not exist, make one
build_dirs() {
	local host_dir=$"$HOME/ScanTargets/Targets/$target"
	if [[ ! -d "$host_dir" ]]; then
		echo "${bold}[+] ${normal}Creating scan directory for target..."
		mkdir $host_dir
		echo "Done."
	else
		echo "${bold}[!] ${normal}Scan directory already exists for host. Not creating."
		echo
	fi

	# Create directory with today's scan date in scan target directory
	if [[ ! -d "$host_dir/$today" ]]; then
		echo "${bold}[+] ${normal}Creating date directory for scan target..."
		mkdir $host_dir/$today
		scan_dir=$host_dir/$today
		echo "Done."
	else
		echo "${bold}[!] ${normal}Today's date directory already exists for scan target. Not creating."
		echo
	fi

	# Send all error messages to error file
	exec 2>$scan_dir/errors.txt
}

# Run initial nmap port sweep to discover open ports
port_sweep() {
	echo "${bold}[+] ${normal}Launching nmap port sweep on all ports..."
	exec 3>>$scan_dir/nmap_portsweep.txt
	nmap -sS -T4 -p- $ip >&3
	if [[ $(cat $scan_dir/nmap_portsweep.txt | grep -i "Host seems down") ]]; then
		echo
		echo "${bold}[!] ${normal}Host appears to be down or blocking probes."
		echo
		echo "Not generating target files."
		echo "$(date): $target $ip" >> $HOME/ScanTargets/blockedscan_hosts.txt
		cat $scan_dir/nmap_portsweep.txt >> $scan_dir/blockedscan.txt
		rm $scan_dir/nmap_portsweep.txt
	elif [[ $(cat $scan_dir/nmap_portsweep.txt | grep -E '^(All).+closed$') ]]; then
		echo
		echo "${bold}[!] ${normal}Host appears to have all of its ports closed."
		echo
		echo "Not generating target files."
		echo "$(date): $target $ip" >> $HOME/ScanTargets/allportsclosed_hosts.txt
		cat $scan_dir/nmap_portsweep.txt >> $scan_dir/allportsclosed.txt
		rm $scan_dir/nmap_portsweep.txt
	else
		awk 'BEGIN{FS="/";} /open/ {print $1;}' $scan_dir/nmap_portsweep.txt | awk '{printf "%s%s",sep,$0; sep=","} END{print ""}' >> $scan_dir/openports.txt
		echo "Done."
	fi
}

# Run deep port scan targeted only at open ports
port_scan() {
	if [[ -s $scan_dir/openports.txt ]]; then
		echo "${bold}[+] ${normal}Launching nmap deep port scan..."
		exec 4>>$scan_dir/nmap
		local open_ports
		for open_ports in $(cat $scan_dir/openports.txt); do 
			nmap -T4 -A -sS -p $open_ports $ip; done >&4
		echo "Done."
	else
		:
	fi
}

# If target is running a web server, launch Nikto scan
nikto_scan() {
	if [[ -s $scan_dir/openports.txt ]]; then
		echo "${bold}[+] ${normal}Checking if host is a web server with port 80 or 443 open..."
		if grep -q "80" $scan_dir/openports.txt; then
			echo "-- Target has port 80 open."
			echo
			echo "${bold}[+] ${normal}Launching nikto scan on port 80 now..."
			exec 5>>$scan_dir/nikto80.txt
			nikto -404code -h http://$ip >&5
			echo "Done."
		elif grep -q "443" $scan_dir/openports.txt; then
			echo "-- Target has port 443 open."
			echo
			echo "${bold}[+] ${normal}Launching nikto scan on port 443 now..."
			exec 7>>$scan_dir/nikto443.txt
			nikto -404code -h https://$ip -ssl >&7
			echo "Done."
		else
			echo
			echo "${bold}[!] ${normal}The target is not running a web server."
			echo
		fi
	else
		:
	fi
}

# PULL PERTINENT SYSTEM INFORMATION FROM SCAN FILES
create_sysinfo() {
	local answer
	if [[ -s $scan_dir/openports.txt ]]; then
		if [[ "$system_info_flag" = "unset" ]]; then
			answer="N"
		else
			answer="Y"
		fi

		if [[ "$answer" = "Y" ]] || [[ "$answer" = "y" ]]; then
			nmap=$scan_dir/nmap
		    echo
		    echo "${bold}[+] ${normal}Creating file with system information..."
		    ipregex='[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}'
		    timeregex='\s[0-9]{2}:[0-9]{2}\s[A-Z]+'
		    srvcregex='^[0-9]+\/[a-z]{3}.+$'

		    local macaddr=$(grep -E '^MAC Address:' <$nmap)
		    local ipaddr=$(grep -o -m 1 -E "$ipregex" <$nmap)
		    local scantime=$(grep -o -E "$timeregex" <$nmap)
		    local openservices=$(grep -E "$srvcregex" <$nmap)

			exec 9>>$scan_dir/system_info
			echo "${bold}*** $target ***" | tr '[:lower:]' '[:upper:]' 
			echo "$today -- $scantime" >&9
			echo >&9
			echo "${normal}IP Address: ${bold}$ipaddr" >&9
			echo "${normal}$macaddr" >&9
			echo >&9
			echo "Open Services: " >&9
			echo "$openservices" >&9
			echo >&9
			echo "Execution script: $0" >&9
			cat $scan_dir/system_info >> $HOME/ScanTargets/$today_hostsinfo.txt
			echo
			echo
			echo
			echo
			cat $scan_dir/system_info
			echo
			echo
			echo
			echo
		elif [[ "$answer" = "N" ]] || [[ "$answer" = "n" ]]; then
			echo "${bold}[!] ${normal}System information will not be collected in additional file."
			echo
		else
			echo "Exiting gracefully."
			exit
		fi
	else
		:
	fi
}

# If no parameters specified, launches in interpretive mode
if [[ -n "$1" ]] && [[ "$(whoami)" = "root" ]]; then
	unset filetargets
	unset fileips
	unset file
	while getopts :t:i:f:su opt; do
		case "$opt" in
			t) 
				target=$OPTARG
			   	echo "Target = $OPTARG" ;;
			i) 
				ip=$OPTARG
			   	echo "IP Address = $OPTARG" ;;
			f) 
				file=$(echo "$OPTARG" | cut -d " " -f 1,2)
				echo $file
			   	echo "Targets and IP Addresses will be pulled from: "
			   	echo "${bold}$OPTARG${normal}"
			   	count=1
			   	while read filetarget fileip; do
					filetargets[$count]=$(echo $filetarget | awk -F "." '{print $1}')
					fileips[$count]=$fileip
					count=$[ $count + 1 ]
				done <"$file" ;;
			s) 
				system_info_flag="set" 
			   	echo "System Information WILL be collected in separate file." 
			   	echo ;;
			u) 
				system_info_flag="unset" 
			   	echo " System Information WILL NOT be collected in separate file."
			   	echo ;;
			*) 
				echo "'$OPTARG' is not a valid parameter [-t,-i,-s,-u]"
			   	exit ;;
		esac
	done
elif [[ -z "$1" ]] && [[ "$(whoami)" = "root" ]]; then
	echo "* Hosts with prior scan directories: "
	echo $(ls -l $HOME/ScanTargets | awk '{print $9}')
	echo
	read -p "** Enter the name of target host: " target
	echo
	read -p "*** Enter the host IP address: " ip
	echo
else
	echo "Command must be ran as 'root'."
	echo "Exiting gracefully."
	exit
fi

# scan hosts from file, command line options, or interpretive mode
if [[ -n ${filetargets[*]} ]] && [[ -n ${fileips[*]} ]]; then
	i=1
	while [[ $i -le $count ]]; do
		target=${filetargets[$i]}
		ip=${fileips[$i]}
		if [[ $(echo $target | wc -c) -gt 1 ]]; then
			echo
			echo "Performing scan on ${bold}$target - $ip"
			echo
			build_dirs
			port_sweep
			port_scan
			nikto_scan
			create_sysinfo
			echo
			echo
			echo "${bold}**** $target - $ip SCAN COMPLETE ****"
			echo
			end=$(date +%s)
			runtime=$((end-start))

			if [[ -s $scan_dir/system_info ]]; then
				echo
				cat $scan_dir/system_info 
				echo
				echo "The script executed in: ${bold}$runtime seconds" | tee -a $scan_dir/system_info
			else
				echo "The script executed in: ${bold}$runtime seconds"
			fi

			echo
			i=$[ $i + 1 ]
		else
			break
		fi
	done
elif [[ -n $target ]] && [[ -n $ip ]]; then
	build_dirs
	port_sweep
	port_scan
	nikto_scan
	create_sysinfo
else
	echo "Exiting gracefully."
	exit
fi

echo
echo "${bold}**** SCAN COMPLETE ****"
echo
