#!/bin/bash
# blago
# 05-21-21

# Check if there are any new executables on my system

today=$(date +%m-%d-%y)
output_path=$HOME/ScriptOutput/executable_count
file_path="$output_path"/"$today"executables.txt
mypath=$(echo $PATH | sed 's/:/ /g')


# Checks $output_path and removes oldest file, leaving only yesterday's file
filecount=1
for exe_file in $(ls $output_path); do
	exe_file[$filecount]="$output_path/$exe_file"
	filecount=$[ $filecount +1 ]
done

if [[ ${exe_file[1]} -nt ${exe_file[2]} ]]; then
	rm ${exe_file[2]}
	yester_file=${exe_file[1]}
elif [[ ${exe_file[1]} -ot ${exe_file[2]} ]]; then
	rm ${exe_file[1]}
	yester_file=${exe_file[2]}
else
	echo "Exiting gracefully."
	exit
fi

# Count all files present in $PATH directories
count=0
for directory in $mypath; do
	search=$(ls $directory)
	for item in $search; do
		count=$[ $count + 1 ]
		item[$count]=$item
	done
	echo "$directory - $count"
	for exe in ${item[*]}; do
		echo -e "\t$exe"
	done
	echo
	count=0
done >$file_path

# Compare newly created file with yesterdays file
echo >> $HOME/ScriptOutput/executable_diff.txt
diff "$file_path" "$yester_file" >> $HOME/ScriptOutput/executable_diff.txt



# Check if there are any new executables created

# today_file=$(date -d "$(ls -la $output_path/$file_path | awk '{print $6,$7,$8}')")
# yester_day=$(date -d "$today_file -1 day" | awk '{print $2}')
# yester_month=$(date -d "$today_file -1 day" | awk '{print $3}')
# yester_date=$(echo "$yester_month $yester_day")
# # echo $yester_date
# # echo
# # echo $yester_day
# # echo $yester_date
# # echo $yester_month


# if [[ $(ls $output_path | wc -w) -ge 2 ]]; then
# 	yester_file=$output_path/$(ls -la $output_path | grep "$yester_date" | awk '{print $9}')
# fi

# diff $today_file $yester_file


# echo $yester_file

