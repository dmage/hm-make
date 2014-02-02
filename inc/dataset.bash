dataset__contains() {
	local dataset_name=${1:?$FUNCNAME: expected dataset_name}
	local value=${2?$FUNCNAME: expected value}

	local ref="$dataset_name[@]"
	if [[ -n "${!ref+defined}" ]]; then
		local -a dataset_values=("${!ref}")

		for i in "${dataset_values[@]}"; do
			if [[ "$i" == "$value" ]]; then
				return 0
			fi
		done
	fi

	return 1
}

dataset__push() {
	local dataset_name=${1:?$FUNCNAME: expected dataset_name}
	local value=${2?$FUNCNAME: expected value}

	local ref="$dataset_name[@]"
	if [[ -n "${!ref+defined}" ]]; then
		local -a dataset_values=("${!ref}")

		for i in "${dataset_values[@]}"; do
			if [[ "$i" == "$value" ]]; then
				return 0
			fi
		done

		declare -ga $dataset_name='("${dataset_values[@]}" "$value")'
	else
		declare -ga $dataset_name='("$value")'
	fi
}
