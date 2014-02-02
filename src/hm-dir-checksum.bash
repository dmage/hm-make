#!/bin/bash
set -efu -o pipefail

TARGET=$1

checksum() {
	sha1sum - | cut -d' ' -f1
}

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
