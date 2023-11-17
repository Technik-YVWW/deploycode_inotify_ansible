#!/bin/bash
# shellcheck disable=all

# Ermittle das Verzeichnis, in dem das Skript liegt
# Verwende "readlink" für absolute Pfade und "dirname" für relative Pfade
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_DIR

. ./lib/functions

# Rufe die Funktion watch_and_run_playbook auf

## Pushes all for Server 172.0.0.9
watch_and_run_playbook "/git/ansible_ww_inventorys.git" "inventorys_to_semaphore" &
watch_and_run_playbook "/git/ansible_clients_linux.git" "ansible_clients_linux" &
watch_and_run_playbook "/git/ansible_clients_windows.git" "ansible_clients_windows" &
watch_and_run_playbook "/git/ansible_devices_openwrt.git" "ansible_devices_openwrt" &
watch_and_run_playbook "/git/openwrt_scripts.git" "openwrt_scripts" "push-to-server" "openwrt_scripts_local" "push-and-compress-local" &
watch_and_run_playbook "/git/ansible_roles_common.git" "ansible_roles_common"
