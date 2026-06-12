#!/bin/sh

set -eu

# Determine the directory in which this script is stored.
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR" || exit 1

bins="deploycode deploycode-test"
folders="/etc/deploycode/configs-available /etc/deploycode/configs-enabled /etc/deploycode/playbooks /etc/deploycode/playbook-vars /etc/deploycode/roles"

echo "Checking folders..."
for folder in $folders; do
	echo "Folder: $folder"
	[ -d "$folder" ] || mkdir -p "$folder"
done

echo "Installing main scripts..."
for bin in $bins; do
	install -m 0755 "$bin" "/usr/bin/$bin"
done

echo "Installing library..."
install -m 0644 usr/lib/libDeploy /usr/lib/libDeploy

echo "Installing playbooks..."
for file in ./etc/deploycode/playbooks/*; do
	[ -r "$file" ] || continue
	install -m 0644 "$file" "/etc/deploycode/playbooks/$(basename "$file")"
done

if [ -d ./etc/deploycode/roles ]; then
	echo "Installing roles..."
	cp -R ./etc/deploycode/roles/. /etc/deploycode/roles/
fi

echo "Installing missing skeleton files..."
for file in ./etc/deploycode/configs-available/* ./etc/deploycode/playbook-vars/*; do
	[ -r "$file" ] || continue
	case "$file" in
		./etc/deploycode/configs-available/*)
			target="/etc/deploycode/configs-available/$(basename "$file")"
			;;
		./etc/deploycode/playbook-vars/*)
			target="/etc/deploycode/playbook-vars/$(basename "$file")"
			;;
	esac

	[ -e "$target" ] || install -m 0644 "$file" "$target"
done

if [ -d "/etc/systemd/system/" ]; then
	echo "Installing systemd service..."
	install -m 0644 etc/systemd/system/deploycode-inotify.service /etc/systemd/system/deploycode-inotify.service
	if command -v systemctl >/dev/null 2>&1; then
		systemctl daemon-reload
	fi
	echo "[INFO] Enable the service with: systemctl enable deploycode-inotify"
	echo "[INFO] Start or stop it with: systemctl start|stop deploycode-inotify"
fi
