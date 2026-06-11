#!/bin/sh

set -eu

# Ermittle das Verzeichnis, in dem das Skript liegt
# Verwende "readlink" für absolute Pfade und "dirname" für relative Pfade
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR" || exit 1

bins="deploycode deploycode-test"
folders="/etc/deploycode/configs-available /etc/deploycode/configs-enabled /etc/deploycode/playbooks /etc/deploycode/playbook-vars /etc/deploycode/roles"

echo Checking Folders...
for folder in $folders; do
	echo Folder: "$folder"
	[ -d "$folder" ] || mkdir -p "$folder"
done

echo "Installing main scripts..."
for bin in $bins; do
	install -m 0755 "$bin" "/usr/bin/$bin"
done

echo Installing Libraries ..
install -m 0644 usr/lib/libDeploy /usr/lib/libDeploy

for file in ./etc/deploycode/playbooks/*; do
	[ -r "$file" ] || continue

	echo file: "$file"
	cp -rv "$file" /etc/deploycode/playbooks
done

[ -d "/etc/systemd/system/" ] && {
	echo Copying Service Script...
	install -m 0644 etc/systemd/system/deploycode-inotify.service /etc/systemd/system/deploycode-inotify.service
	systemctl daemon-reload
	echo "[INFO] You can activate it with: systemctl enable deploycode-inotify"
	echo "[INFO] You can start or stop it with: systemctl start|stop deploycode-inotify"
}
