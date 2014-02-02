all: impl/hm-dir-checksum impl/hm-get-mode

impl/hm-dir-checksum:
	ln -s ../src/hm-dir-checksum.bash impl/hm-dir-checksum

impl/hm-get-mode: src/hm-get-mode.c
	gcc src/hm-get-mode.c -o impl/hm-get-mode
