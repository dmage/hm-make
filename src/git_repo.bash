#!/bin/bash
set -efu -o pipefail

TARGET_DIR=$1
GIT_REPO=$2

if [[ -e "$TARGET_DIR" ]]; then
	cd "$TARGET_DIR"
	git pull --ff-only --all
else
	git clone "$GIT_REPO" "$TARGET_DIR"
fi