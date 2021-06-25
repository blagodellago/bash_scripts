#!/bin/bash
# blago
# 05-27-21

###########################################################
# Store reminders for certain tasks/activities in ~/Tasks #
###########################################################
# Syntax: $tasks <task_name> <task_date> <priority_level> #
###########################################################

# check if taskname specified as parameter
if [[ -n "$1" ]]; then
	taskname=$1
else
	read -p "Enter name of task: " taskname
fi

taskname=$(echo $taskname | sed 's/ /_/g')

# check if taskdate was specifies as parameter
if [[ -n "$2" ]]; then
	taskdate=$2
else
	read -p "Enter date of task (mm-dd-yy || mm/dd/yy): " taskdate
fi

# check if a task priority was specified
if [[ -n "$3" ]] && [[ "$3" -le 3 ]]; then
	priority=$3
elif [[ -n "$3" ]]; then
	echo "That is an invalid priority."
	read -p "Enter a priority level (1:low, 2:medium, 3:high): " priority
	echo
else
	read -p "Enter a priority level (1:low, 2:medium, 3:high): " priority
	echo
fi

# format date into day, month, and year for directories
if [ $(echo "$taskdate" | grep -E '[0-9]{2}-[0-9]{2}-[0-9]{2}') ]; then
	taskmonth=$(echo "$taskdate" | cut -d "-" -f 1)
	taskday=$(echo "$taskdate" | cut -d "-" -f 2)
	taskyear=20$(echo "$taskdate" | cut -d "-" -f 3)
elif [ $(echo "$taskdate" | grep -E '[0-9]{2}/[0-9]{2}/[0-9]{2}') ]; then
	taskmonth=$(echo "$taskdate" | cut -d "-" -f 1)
	taskday=$(echo "$taskdate" | cut -d "-" -f 2)
	taskyear=20$(echo "$taskdate" | cut -d "-" -f 3)
else
	echo "Please specify date in format: mm-dd-yy OR mm/dd/yy"
	echo "Exiting."
	echo
	exit
fi

# build task destination directory
base_dir=$HOME/Tasks
mkdir -p $base_dir/$taskyear/$taskmonth/$taskday
taskdestination=$base_dir/$taskyear/$taskmonth/$taskday/$priority--$taskname.txt

touch $taskdestination
