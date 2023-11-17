#!/bin/sh
# shellcheck disable=all

if [ -r "./usr/lib/libDeploy" ]; then . ./usr/lib/libDeploy; else . /usr/lib/libDeploy; fi

# FIle Ignored by Shellcheck, because we test new Methods.

echo Old Iterate Method:
for file in $(ls ./etc/deploycode/playbooks); do
	[ -f "./etc/deploycode/playbooks/$file" ] && {
		echo file: "$file"
	}
done

echo New Iterate Method:
for file in "./etc/deploycode/playbooks"/*; do
	[ -f "$file" ] && {
		echo file: "$file"
		echo cp -rv "$file" /etc/deploycode/playbooks
	}
done

echo OLD: COunt Method:
count_pids=$(ls etc/ 2>/dev/null | wc -w)
echo $count_pids

echo NEW Cont Method
count_folder_files "./etc"
#count_pids=$(find ./etc/* -maxdepth 0 -type f | wc -l)
#echo $count_pids

echo "with extension:"
count_folder_files "./etc/deploycode/playbooks" "yml"
