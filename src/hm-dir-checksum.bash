#!/bin/bash
set -efu -o pipefail

TARGET=$1

if [[ -n "$(which sha1sum)" ]]; then
	checksum() {
		sha1sum - | cut -d' ' -f1
	}
elif [[ -n "$(which shasum)" ]]; then
	checksum() {
		shasum - | cut -d' ' -f1
	}
else
	echo "$0: no sha1sum or shasum found" >&2
	exit 1
fi

PATH="$PATH:$(pwd)"
cd "$TARGET"

while IFS= read -r -d $'\0' file; do
	printf "%s\0%s\0" "$file" "$(hm-get-mode "$file")"
	if [[ -f "$file" ]]; then
		printf "%s\0" "$(cat "$file" | checksum)"
	elif [[ -L "$file" ]]; then
		printf "%s\0" "$(readlink "$file")"
	fi
	printf "\0"
done < <(find . -print0 | LC_ALL=C sort -z) | checksum
