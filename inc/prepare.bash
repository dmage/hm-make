prepare__init() {
	prepare__tmp_dir=$(mktemp -d -t hm-make.XXXXXXXXXX)
	trap prepare__cleanup EXIT

	prepare__files_dir="$prepare__tmp_dir/files"
	mkdir "$prepare__files_dir"

	prepare__sources_dir="$prepare__tmp_dir/sources"
	mkdir "$prepare__sources_dir"
}

prepare__cleanup() {
	if [[ -n "${prepare__tmp_dir+x}" ]]; then
		if [[ -n "${HM_KEEP+x}" ]]; then
			echo "[keep] prepare__tmp_dir: $prepare__tmp_dir"
		else
			rm -rf -- "$prepare__tmp_dir" || true
		fi
	fi
}

prepare__files() {
	local pkg_path=$1
	local pkg_id=$(pkg__get_pkg_id "$pkg_path")

	mkdir -p "$prepare__files_dir/$pkg_id"

	if [[ -x "$pkg_path/prepare" ]]; then
		(
			if [[ ! -n ${HM_VERBOSE+x} ]]; then
				exec 1>/dev/null
			fi

			cd "$pkg_path"
			"$pkg_path/prepare"
		)
	fi

	rsync -a "$pkg_path/" "$prepare__files_dir/$pkg_id/"
}

prepare__sources() {
	# 'local' would override hm-dir-checksum exit code
	pkg_checksum=$(hm-dir-checksum "$prepare__files_dir/$pkg_id/")

	mkdir -p "$prepare__sources_dir/$pkg_id/"
	mv "$prepare__files_dir/$pkg_id" "$prepare__sources_dir/$pkg_id/$pkg_checksum"
}
