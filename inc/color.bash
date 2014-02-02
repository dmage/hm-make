color() {
	if [ -n "$TERM" -a "$TERM" != "unknown" ]; then
		tput -T "$TERM" "$@" || true
	fi
}

color__bold=$(color bold)
color__red=$(color setaf 1)
color__green=$(color setaf 2)
color__blue=$(color setaf 4)
color__yellow=$(color setaf 3)
color__reset=$(color sgr0)
