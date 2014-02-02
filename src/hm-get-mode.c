#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

int main(int argc, char* argv[])
{
	if (argc != 2)
	{
		fprintf(stderr, "usage: %s FILENAME\n", argv[0]);
		return EXIT_FAILURE;
	}

	struct stat s;
	if (lstat(argv[1], &s) != 0) {
		perror("lstat");
		return EXIT_FAILURE;
	}

	printf("%06o\n", s.st_mode);

	return EXIT_SUCCESS;
}
