all: impl/hm-dir-checksum impl/git_repo impl/hm-get-mode

impl/hm-dir-checksum:
	ln -s ../src/hm-dir-checksum.bash impl/hm-dir-checksum

impl/git_repo:
	ln -s ../src/git_repo.bash impl/git_repo

impl/hm-get-mode: src/hm-get-mode.c
	gcc src/hm-get-mode.c -o impl/hm-get-mode
