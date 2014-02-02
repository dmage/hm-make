discover__gencode() {
	echo 'set -eu -o pipefail'
	echo

	real__dump

	echo 'mkdir -p "$REAL_HM_DIR"'
	echo

	for pkg_path in "${pkg__ordered[@]}"; do
		if [ -r "$pkg_path/discover" ]; then
			echo "# $pkg_path/discover"
			cat "$pkg_path/discover"
			echo
		fi
	done

	declare -f dump__bash_var
	echo 'dump__bash_var DISCOVER_'
}

discover__run() {
	if [[ -n "${HM_GENERATED+x}" ]]; then
		echo "$color__yellow=== discover [generated code] ===$color__reset"
		discover__gencode
		echo "$color__yellow=== cut ===$color__reset"
		echo
	fi

	eval "$(discover__gencode | real__bash || echo "exit $?")"

	for var_name in "${!DISCOVER_@}"; do
		export "$var_name"
	done
}
