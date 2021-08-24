#!/bin/bash
# blagodellago
# 08-21-21

##########################################################################
# Search for connection frequency, duration, data transfers, persistency #
##########################################################################

# define input and output directories and validate them
if [[ "$1" ]]; then
	:
else
	echo
    	echo "[!] No date supplied as parameter [!]"
        echo "    The correct format is: 'YYYY-MM-DD'"
        exit
fi

input_dir="/nsm/zeek/logs/$1"
output_dir="$HOME/RITAlogs/$1"
out_file="$output_dir/parsed.txt"
home_ips="$HOME/data/home_ip_addrs.txt"

# validate existence of input_dir
if [[ -d $input_dir ]]; then
	:
else
	echo "Could not find directory: $input_dir"
	echo "Please ensure accuracy of date supplied"
    echo "The correct format is: 'YYYY-MM-DD'"
	exit
fi

# if directories do not exist, create them
mkdir -p "$output_dir"

# group all conn.log.gz files together
cat "$input_dir"/conn.*.gz > "$output_dir/concat_conns.log.gz"
dailyconns="$output_dir/concat_conns.log.gz"

# FREQ_CONNS: execute script to check frequency of connections
zcat "$dailyconns" \
	| jq -j '.["id.orig_h"], " ", .["id.resp_h"], "\n"' \
	| sort | uniq -c | sort -rn | head -25 \
	> "$output_dir/freq_unparsed.txt"

# parse out local-local ip connections
echo "FREQUENCY OF CONNECTIONS:" > "$out_file"
while IFS=" " read -r frequency source dest; do
	if [[ $(cat "$home_ips" | grep "$source") ]] && [[ $(cat "$home_ips" | grep "$dest") ]]; then
		:
	else
		echo "$frequency $source $dest" >> "$out_file"
	fi
done < "$output_dir/freq_unparsed.txt"

# BYTES_TRANSFERRED: execute script to see total bytes tranferred over connection
zcat "$dailyconns" \
	| jq -j '.["id.orig_h"], " ", .["id.resp_h"], " ", .["orig_bytes"], "\n"' \
	| sort | grep -v '-' | grep -v 'null' \
	| datamash -t ' ' -g 1,2 sum 3 | sort -k 3 -rn | head -50 \
	> "$output_dir/bytes_unparsed.txt"

# convert bytes transferred to kilobytes transferred
cat "$output_dir/bytes_unparsed.txt" | awk '{print $1,$2,$3/1024}' > "$output_dir/bytes_unparsed.txt"

# parse out local-local ip connections
echo >> "$out_file"
echo "BYTES TRANSFERRED:" >> "$out_file"
while IFS=" " read -r source dest orig_bytes; do \
	if [[ $(cat "$home_ips" | grep "$dest") ]]; then
		:
	else
		echo "$source $dest $orig_bytes" >> "$out_file"
	fi
done < "$output_dir/bytes_unparsed.txt"

# TOTAL_DURATION: execute script to see total duration of each connection
zcat "$dailyconns" \
	| jq -j '.["id.orig_h"], " ", .["id.resp_h"], " ", .["duration"], "\n"' \
	| sort | grep -v '-' | grep -v 'null' | datamash -t ' ' -g 1,2 sum 3 \
	| sort -k 3 -rn | head -20 \
	> "$output_dir/duration_unparsed.txt"

# parse out local-local ip connections
echo >> "$out_file"
echo "TOTAL DURATION OF CONNECTIONS" >> "$out_file"
while IFS=" " read -r source dest duration; do
	if [[ $(cat "$home_ips" | grep "$source") ]] && [[ $(cat "$home_ips" | grep "$dest") ]]; then
		:
	else
		echo "$duration $source $dest" >> "$out_file"
	fi
done < "$output_dir/duration_unparsed.txt"

# remove concat file
rm "$dailyconns"

# print output to display
cat "$out_file"
