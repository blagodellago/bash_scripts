#!/bin/bash
# blago
# 05-27-21

####################################################################
# Specify user account name and kill all processes spawned by user #
####################################################################

#import process_yn function from function library
source $HOME/bash_scripts/blagos_functions.sh

# checks if user was specified as parameter
if [[ -n $1 ]]; then
	user=$1
else
	read -p "Enter the user account to kill: " user
fi

# ensures user account exists on system
if [[ $(cat /etc/passwd | grep -w $user) ]]; then
	echo "$user exists."
	echo "Proceeding with killing all user processes.."
	echo
else
	echo "$user does not exist."
	echo "Exiting."
	echo
	exit
fi

# define variables to display user processes and kill them
userprocs="ps -u $user --no-heading"
killuserprocs="xargs -d \\n /usr/bin/sudo /usr/bin/kill -9"

# display user processes to user
echo "Current $user processes: "
echo 
$userprocs
echo

question="Would you like to kill these processes? "
yesline="Killing user processes now..."
yescommand=$($userprocs | gawk '{print $1}' | $killuserprocs)
noline="Not killing user processes. Exiting." 
nocommand=exit
process_yn

# verify processes were killed
echo "$user processes after the savagery: "
echo 
$userprocs
echo

echo
echo "Processes successfully killed."
echo "Exiting."
exit
