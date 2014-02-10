pkg__get_pkg_id() {
	test -d "$1"

	local pkg_path=$(cd "$1"; pwd -P)
	local repo_path=$(cd "$pkg_path/.."; pwd -P)

	local repo_name=$(basename "$repo_path")
	local pkg_name=$(basename "$pkg_path")

	echo "$repo_name/$pkg_name"
}

__pkg__traverse() {
	local pkg_path=${1:?$FUNCNAME: expected pkg_path}
	shift

	test -d "$pkg_path"

	local pkg_path=$(cd "$pkg_path"; pwd -P)
	local pkg_id=$(pkg__get_pkg_id "$pkg_path")

	for parent_path; do
		if [[ "$pkg_path" == "$parent_path" ]]; then
			echo "$FUNCNAME: loop detected" >&2
			for (( i = $#; $i > 0; i-- )); do
				echo "  ${!i}"
			done
			echo "  $pkg_path (repeated)" >&2
			exit 1
		fi
	done

	if [[ -d "$pkg_path/inherit" ]]; then
		for inherit_pkg_path in "$pkg_path/inherit"/*; do
			__pkg__traverse "$inherit_pkg_path" "$pkg_path" "$@"
		done
	fi

	local pkg_idx=-1
	local new=0
	for idx in "${!pkg__ordered[@]}"; do
		if [[ "${pkg__ordered[$idx]}" == "$pkg_path" ]]; then
			pkg_idx=$idx
			break
		fi
	done
	if [[ $pkg_idx -eq -1 ]]; then
		new=1
		pkg_idx=${#pkg__ordered[@]}
		pkg__ordered[$pkg_idx]=$pkg_path
	fi

	local idx=${#pkg__verbose_ordered[@]}
	pkg__verbose_ordered[$idx]=$pkg_path
	pkg__verbose_depth[$idx]=$#
	pkg__verbose_new[$idx]=$new
}

pkg__traverse() {
	pkg__ordered=()
	pkg__verbose_ordered=()
	pkg__verbose_depth=()
	pkg__verbose_new=()
	__pkg__traverse "$@"
}
