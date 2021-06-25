#!/bin/bash
# blago
# 05-26-21

############################################################
# Archive designated files and directories daily at 5:00pm #
############################################################

arcdate=$(date +%m-%d-%y)
arcname=archive$arcdate.tar.gz

# designate file to read from with files/dirs to archive
archive_list=/archive/archive_list
destination=/archive/$arcname

############################################################

# ensure archive_list file exists
if [ -f $archive_list ]; then
	:
else
	echo
	echo "The list of files and directories to back up does not exist."
	echo "Cannot perform the archive. Exiting."
	echo
	exit
fi

# build the names of all the files/dirs to backup
file_num=1

exec < $archive_list # receive standard input from file

read filename # read first record in file
while [ $? -eq 0 ]; do # if exit is non-0, break loop
	if [ -f $filename ] || [ -d $filename ]; then # ensures file/dir exists
		file_list="$file_list $filename" 
	else
		echo
		echo "$filename does not exist."
		echo "$filename is listed on line $file_num of $archive_list" # prints location of missing file in archive_list
		echo "Continuing to build archive list..."
		echo
	fi
	file_num=$[$file_num + 1] # increments a line to capture location of file in archive_list
	read filename # read next record in file
done

############################################################

# backup files and compress archive
echo "Starting archive..."
echo

tar -czf $destination $file_list 2> /dev/null

echo "Archive completed."
echo
echo "Archive can be found at: $destination"
echo
exit
