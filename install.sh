#!/bin/sh

# Ermittle das Verzeichnis, in dem das Skript liegt
# Verwende "readlink" für absolute Pfade und "dirname" für relative Pfade
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_DIR

echo Checking Foldrs...
folders="/etc/deploycode/configs-available /etc/deploycode/configs-enabled /etc/deploycode/playbooks /etc/deploycode/playbook-vars /usr/lib/libDeploy"
for folder in $folders; do
    echo Folder: $folder
    [ ! -d "$folder" ] && mkdir -p $folder
done

echo "Installig Mainscript..."
cp -fvu deploycode /usr/bin

echo Installing Libaries..
cp -fvu usr/lib/libDeploy /usr/lib

for file in $(ls ./etc/deploycode/playbooks); do
    [ -f "./etc/deploycode/playbooks/$file" ] && {
        echo file: $file
        cp -rv ./etc/deploycode/playbooks/$file /etc/deploycode/playbooks
    }
done