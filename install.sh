#!/bin/sh

# Ermittle das Verzeichnis, in dem das Skript liegt
# Verwende "readlink" für absolute Pfade und "dirname" für relative Pfade
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR" || exit 1

bins="deploycode deploycode-test"
folders="/etc/deploycode/configs-available /etc/deploycode/configs-enabled /etc/deploycode/playbooks /etc/deploycode/playbook-vars"

echo Checking Foldrs...
for folder in $folders; do
	echo Folder: "$folder"
	[ ! -d "$folder" ] && mkdir -p "$folder"
done

echo "Installig Mainscript..."
for bin in $bins; do
	cp -fvu "$bin" /usr/bin
done

echo Installing Libaries..
cp -fvu usr/lib/libDeploy /usr/lib

for file in ./etc/deploycode/playbooks/*; do
	[ ! -r "$file" ] && continue

	echo file: "$file"
	cp -rv "$file" /etc/deploycode/playbooks
done

echo Copying Service Skript...
cp -fvu etc/systemd/system/deploycode-inotify.service /etc/systemd/system/
echo "[INFO] You Can Activate it by systemctl enable deploycode-inotify"
echo "[INFO] You Can Start/Stop it by systemctl start/stop deploycode-inotify"
