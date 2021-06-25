#!/bin/bash
# 05-20-21    blago

# DESCRIPTION: Copy recent files to appropriate directory

if [[ -n $1 ]] && [[ -n $2 ]]; then
	search_dir=$1
	storage_dir=$2
	echo
elif [[ -n $1 ]] && [[ -z $2 ]]; then
	search_dir=$1
	echo -n "Enter file extension, which will be used to store results in $HOME dir: "
	read stor_response
	storage_dir=$stor_response
	echo
else
	echo -n "Enter directory to search: "
	read search_response
	search_dir=$search_response
	echo
	echo -n "Enter file extension, which will be used to store results in $HOME dir: "
	read stor_response
	storage_dir=$stor_response
fi

mkdir -p $HOME/$2

find $search_dir -mtime 1 -type f -iname "*.$2" | xargs -I %

cp % $HOME/$2
