#!/bin/sh

set -eu

files="deploycode deploycode-test install.sh usr/lib/libDeploy"

for file in $files; do
	dash -n "$file"
	bash -n "$file"
done

if command -v shellcheck >/dev/null 2>&1; then
	shellcheck $files
else
	echo "[INFO] shellcheck is not installed; skip shellcheck validation."
fi

if command -v shfmt >/dev/null 2>&1; then
	shfmt -d $files
else
	echo "[INFO] shfmt is not installed; skip shfmt formatting check."
fi
