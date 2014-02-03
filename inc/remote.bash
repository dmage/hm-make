remote__init() {
	remote__tmp_dir=$(mktemp -d -t hm-make.XXXXXXXXXX)
	trap remote__cleanup EXIT

	remote__files_dir="$remote__tmp_dir/files"
	mkdir -p "$remote__files_dir"

	remote__root_dir="$remote__tmp_dir/root"
	mkdir -p "$remote__root_dir"

	remote__index="$remote__tmp_dir/index"
	touch "$remote__index"
}

remote__cleanup() {
	if [[ -n "${remote__tmp_dir+x}" ]]; then
		if [[ -n "${HM_KEEP+x}" ]]; then
			echo "[keep] remote__tmp_dir: $remote__tmp_dir"
		else
			rm -r -- "$remote__tmp_dir" || true
		fi
	fi
}

remote__package() {
	local pkg_id="$1"
	local version="$2"

	local HM_SOURCES_DIR="$REAL_HM_DIR/sources/$pkg_id/$version"
	local HM_INSTALL_DIR="$remote__files_dir/$pkg_id/$version"
	mkdir -p "$HM_INSTALL_DIR"

	if [ -d "$REAL_FILES_DIR/$pkg_id/$version" ]; then
		if [[ -n "${HM_VERBOSE+x}" ]]; then
			printf "($color__blue$color__bold%*d$color__reset of $color__blue$color__bold%d$color__reset) %s\n" "${#total}" "$step" "$total" "$pkg_id"
		fi

		rsync -a "$REAL_FILES_DIR/$pkg_id/$version/" "$HM_INSTALL_DIR/"

		return 0
	fi

	if [[ -n "${HM_VERBOSE+x}" ]]; then
		printf "($color__yellow$color__bold%*d$color__reset of $color__yellow$color__bold%d$color__reset) %s\n" "${#total}" "$step" "$total" "$pkg_id"
	fi

	if [ -x "$HM_SOURCES_DIR/install" ]; then
		export HM_SOURCES_DIR
		export HM_INSTALL_DIR
		export HM_RSYNC="rsync"

		# for hm-make v1
		export HM_REAL_ROOT="$REAL_ROOT"
		export HM_WORKDIR="$HM_INSTALL_DIR"
		export HM_LOCAL_RSYNC="rsync"

		pushd "$HM_SOURCES_DIR" >/dev/null
		local retcode=0
		"$HM_SOURCES_DIR/install" || retcode=$?
		popd >/dev/null

		if [[ $retcode -ne 0 ]]; then
			echo " $color__red$color__bold*$color__reset "
			echo " $color__red$color__bold*$color__reset $pkg_id ($version) exited with code $retcode"
			echo " $color__red$color__bold*$color__reset $HM_SOURCES_DIR/install"
			echo " $color__red$color__bold*$color__reset "
			exit $retcode
		fi
	elif [ -d "$HM_SOURCES_DIR/files" ]; then
		rsync -a "$HM_SOURCES_DIR/files/" "$HM_INSTALL_DIR/"
	fi
}

remote__install() {
	cd "$REAL_HM_DIR/sources"

	local pkgs=(*/*)
	total=${#pkgs[@]}
	step=0
	for pkg_id in "${pkgs[@]}"; do
		(( step += 1 ))

		pushd $pkg_id >/dev/null
		local versions=(*)
		popd >/dev/null

		if [[ "${#versions[@]}" -gt 1 ]]; then
			echo "$pkg_id: found ${#versions[@]} versions" >&2
			exit 1
		elif [[ "${#versions[@]}" -ne 1 ]]; then
			echo "$pkg_id: no sources found" >&2
			exit 1
		fi

		local version="${versions[0]}"
		if [[ "$version" == "*" ]]; then
			echo "$pkg_id: no sources found" >&2
			exit 1
		fi

		remote__package "$pkg_id" "$version" "$step" "$total"
	done
	if [[ -n "${HM_VERBOSE+x}" ]]; then
		echo
	fi
}

remote__create_symlinks_for_pkg_files() {
	local REPO_AND_PKG_NAME=$1

	while IFS= read -r -d $'\0' file; do
		mkdir -p "$(dirname "$remote__root_dir/${file#./}")"
		ln -s "$REAL_FILES_DIR/$REPO_AND_PKG_NAME/${file#./}" "$remote__root_dir/${file#./}"
		printf "%s\0" "$REAL_ROOT/${file#./}" >>"$remote__index"
	done < <(cd "$remote__files_dir/$REPO_AND_PKG_NAME"; find . -not -type d -print0)
}

remote__create_symlinks_for_all_pkg_files() {
	pushd "$remote__files_dir" >/dev/null
	REPO_AND_PKG_ARRAY=(*/*/*)
	popd >/dev/null

	for REPO_AND_PKG_NAME in "${REPO_AND_PKG_ARRAY[@]}"; do
		remote__create_symlinks_for_pkg_files "$REPO_AND_PKG_NAME"
	done
}

remote__remove_broken_links() {
	while IFS= read -r -d $'\0' file; do
		LINK_TARGET=$(readlink "$file")
		if [[ "x$LINK_TARGET" != "x${LINK_TARGET#$REAL_FILES_DIR/}" ]]; then
			mkdir -p "$(dirname "$REAL_BACKUP_ROOT_DIR/${file#$REAL_ROOT/}")"
			mv -n ${HM_VERBOSE+-v} "$file" "$REAL_BACKUP_ROOT_DIR/${file#$REAL_ROOT/}"
			rmdir -p "$(dirname "$file")" 2>/dev/null || true
		fi
	done < <(
		if [ -r "$REAL_INDEX" ]; then
			xargs -0 -I'{}' -a "$REAL_INDEX" find -L '{}' -type l -print0 2>/dev/null
		else
			find -L "$REAL_ROOT" -type l -print0 2>/dev/null
		fi
	)
}

remote__main() {
	remote__init

	echo "$color__bold>>>$color__reset Installing packages"
	remote__install

	remote__create_symlinks_for_all_pkg_files

	mkdir -p "$REAL_BACKUP_FILES_DIR"
	rsync -a "$remote__files_dir/" "$REAL_FILES_DIR/" --backup-dir="$REAL_BACKUP_FILES_DIR" --backup

	mkdir -p "$REAL_BACKUP_ROOT_DIR"
	rsync -a "$remote__root_dir/" "$REAL_ROOT/" --backup-dir="$REAL_BACKUP_ROOT_DIR" --backup
	rmdir "$REAL_BACKUP_ROOT_DIR" 2>/dev/null || true

	rsync -a "$remote__files_dir/" "$REAL_FILES_DIR/" --backup-dir="$REAL_BACKUP_FILES_DIR" --backup --delete
	rmdir "$REAL_BACKUP_FILES_DIR" 2>/dev/null || true

	remote__remove_broken_links

	mv "$remote__index" "$REAL_INDEX"
}

remote__gencode() {
	echo 'set -eu -o pipefail'
	echo

	dump__bash_var HM_
	dump__bash_var REAL_
	dump__bash_var DISCOVER_
	dump__bash_var color__
	dump__bash_func remote__

	echo 'remote__main'
}

remote__run() {
	remote__gencode | real__bash
}
