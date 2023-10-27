#!/bin/sh

# Checlking the inotify Executable
tool_inotifywait=$(which inotifywait)
[ ! -x "$tool_inotifywait" ] && {
    echo "The Inotifywait tool Can not be found. Please install it first"
    exit 0
}

### Get the COnfig name to test;
config_name="$1"
[ -z "$config_name" ] && {
    echo "Error: this is a Test Script. Overgive a File name Placed in $config_folder as First Patameter."
    echo "Aborting Script"
    exit 1
}

# Get Libaries.
[ -f "/usr/lib/libDeploy" ] && . /usr/lib/libDeploy || . ./usr/lib/libDeploy

# Search for Playbook Folders..
pb_folder="/etc/deploycode/playbooks/"
[ ! -d "$pb_folder" ] && pb_folder="./etc/deploycode/playbooks"

[ ! -d "$pb_folder" ] && {
    echo "Error! Can not found the Playbook folder. Aborting Script."
    exit 0
}

pb_vars_folder="/etc/deploycode/playbook-vars/"
[ ! -d "$pb_vars_folder" ] && {
    echo "Error! Can not found the Playbook-Vars Folder folder ($pb_vars_folder) folder. Aborting Script."
    exit 0
}

config_folder="/etc/deploycode/configs-enabled"
[ ! -d "$config_folder" ] && {
    echo "Error! Can not found the Config-Enabled folder ($config_folder) folder. Aborting Script."
    exit 0
}

cd $config_folder
config_file="${config_folder}/${config_name}.conf"
[ ! -f "$config_file" ] && {
    echo "Error!: The File $config_file does not exist"
    echo "Aborting Script"
    exit 2
}

watch_for_run_pb "$config_file" "" "" "1"
