#!/bin/bash
# Some constant
RED_COLOR=`tput setaf 1`
GREEN_COLOR=`tput setaf 2`
RESET_COLOR=`tput sgr0`

# Some variable
mode='0'
project_dir=`pwd`


# Check input parameter
if [ $# -ne 1 ]
then
    echo "Usage: data_demo.sh apply | recove"
    echo ""
    echo "data_demo.sh apply :"
    printf "\t apply data demo to your project. Data on file data_demo.yml. Current data will be backup with name db/backup.yml\n"
    echo "data_demo.sh recove:"
    printf "\t rollback data from backuped db/backup.yml\n"
    exit
fi

if [ "$1" == "apply" ]
then
    echo "${GREEN_COLOR}Apply mode!${RESET_COLOR}"
    mode='1'
else
    if [ "$1" != "recove" ]
    then
	if [ "$1" == 'backup' ]
	then
	    echo "${GREEN_COLOR}Backup mode!${RESET_COLOR}"
	    mode='3'
	else
	    echo "${RED_COLOR}Unknown mode!${RESET_COLOR}"
	    echo "Usage: data_demo.sh apply | recove"
	    echo ""
	    echo "data_demo.sh apply :"
	    printf "\t apply data demo to your project. Data on file data_demo.yml. Current data will be backup with name db/backup.yml\n"
	    echo "data_demo.sh recove:"
	    printf "\t rollback data from backuped db/backup.yml\n"
	    exit
	fi
    else
	echo "${GREEN_COLOR}Recove mode!${RESET_COLOR}"
	mode='2'
    fi
fi

if [ "$mode" == "1" ]
then
    if [ ! -f "./data_demo.tar" ]
    then
	echo "${RED_COLOR}File data_demo.yml was missing!${RESET_COLOR}"
	exit
    fi
fi

# Install gem yaml_db
echo "${GREEN_COLOR}Install yaml_db gem!${RESET_COLOR}"
yaml_db_row=`cat Gemfile | grep "gem 'yaml_db'"`
if [ "$yaml_db_row" != "" ]
then
    echo "Gem \"yaml_db\" was added on Gemfile!"
else
    echo "Gem \"yaml_db\" not found on Gemfile!"
    echo "Now, add \"gem 'yaml_db'\" to Gemfile"
    echo "gem 'yaml_db'" >> Gemfile
fi
bundle update
bundle install

if [ "$mode" == "1" ]
then
    if [ ! -f "./db/backup.tar" ]
    then
	if [ -f "./db/data.yml" ]
	then
	    rm -f ./db/data.yml
	fi
	rm -rf /tmp/backup
	mkdir /tmp/backup
	rake db:data:dump
	mv -f ./db/data.yml /tmp/backup/
	mv -f /tmp/backup/data.yml /tmp/backup/backup.yml
	cd ./public/
	cp -rfv uploads /tmp/backup/
	cd /tmp/
	tar -cvf backup.tar backup
	mv backup.tar "$project_dir/db/"
    fi

    cd "$project_dir/"
    rm -rf /tmp/data_demo.tar
    cp -f ./data_demo.tar /tmp
    cd /tmp
    rm -rf ./data_demo
    tar -xvf data_demo.tar

    cp -f ./data_demo/data_demo.yml "$project_dir/db/data.yml"
    cd "$project_dir"
    rake db:data:load
    cd ./public
    rm -rf uploads
    mv /tmp/data_demo/uploads .
    rm -rf /tmp/data_demo /tmp/data_demo.tar
    cd "$project_dir"
    rm -rf ./db/data.yml
    echo "${GREEN_COLOR}Done!${RESET_COLOR}"
else
    if [ "$mode" == "2" ]
    then
	if [ ! -f "./db/backup.tar" ]
	then
	    echo "${RED_COLOR}File db/backup.tar was missing!${RESET_COLOR}"
	    echo "${RED_COLOR}Can't recove!${RESET_COLOR}"
	    exit
	fi

	mv ./db/backup.tar /tmp/
	cd /tmp
	tar -xvf backup.tar
	cd "$project_dir"
	mv -f /tmp/backup/backup.yml ./db/
	mv ./db/backup.yml ./db/data.yml
	rake db:data:load
	cd ./public
	rm -rf uploads
	mv -fv /tmp/backup/uploads ./
	
	rm -rf /tmp/backup /tmp/backup.tar
	cd "$project_dir"
	rm -rf ./db/data.yml
	echo "${GREEN_COLOR}Done!${RESET_COLOR}"
    else
	if [ -f "./db/data.yml" ]
	then
	    rm -f ./db/data.yml
	fi
	rm -rf /tmp/data_demo
	mkdir /tmp/data_demo
	rake db:data:dump
	mv -f ./db/data.yml /tmp/data_demo/
	mv -f /tmp/data_demo/data.yml /tmp/data_demo/data_demo.yml
	cd ./public/
	cp -rfv uploads /tmp/data_demo/
	cd /tmp/
	tar -cvf data_demo.tar data_demo
	mv data_demo.tar "$project_dir"
	echo "${GREEN_COLOR}Done!${RESET_COLOR}"
    fi
fi

