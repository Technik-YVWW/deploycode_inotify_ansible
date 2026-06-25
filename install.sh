#!/bin/sh

set -eu

# Determine the directory in which this script is stored.
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR" || exit 1

bins="ocm-deploy ocm-deploy-test"
folders="/etc/ocm-deploy/configs-available /etc/ocm-deploy/configs-enabled /etc/ocm-deploy/playbooks /etc/ocm-deploy/playbook-vars /etc/ocm-deploy/roles"

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
for file in ./etc/ocm-deploy/playbooks/*; do
	[ -r "$file" ] || continue
	install -m 0644 "$file" "/etc/ocm-deploy/playbooks/$(basename "$file")"
done

if [ -d ./etc/ocm-deploy/roles ]; then
	echo "Installing roles..."
	cp -R ./etc/ocm-deploy/roles/. /etc/ocm-deploy/roles/
fi

echo "Installing missing skeleton files..."
for file in ./etc/ocm-deploy/configs-available/* ./etc/ocm-deploy/playbook-vars/*; do
	[ -r "$file" ] || continue
	case "$file" in
		./etc/ocm-deploy/configs-available/*)
			target="/etc/ocm-deploy/configs-available/$(basename "$file")"
			;;
		./etc/ocm-deploy/playbook-vars/*)
			target="/etc/ocm-deploy/playbook-vars/$(basename "$file")"
			;;
	esac

	[ -e "$target" ] || install -m 0644 "$file" "$target"
done

if [ -d "/etc/systemd/system/" ]; then
	echo "Installing systemd service..."
	install -m 0644 etc/systemd/system/ocm-deploy.service /etc/systemd/system/ocm-deploy.service
	if command -v systemctl >/dev/null 2>&1; then
		systemctl daemon-reload
	fi
	echo "[INFO] Enable the service with: systemctl enable ocm-deploy"
	echo "[INFO] Start or stop it with: systemctl start|stop ocm-deploy"
fi
