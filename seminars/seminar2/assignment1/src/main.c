#include <stdio.h>
#include <stdlib.h>

#include "libmin.h"

int main(int argc, const char* argv[]) {
	int* a;
	argc--;
	do {
		a = malloc(argc * sizeof(int));
	} while (a == 0);
	
	int i = 0;
	while (*++argv) {
		a[i++] = atoi(*argv);
	}

	printf("%d\n", min(a, argc * sizeof(int)));

	free(a);

	return 0;
}