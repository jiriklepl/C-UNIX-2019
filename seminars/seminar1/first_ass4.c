#include <stdio.h>
#include <stdlib.h>

int main(void) {
	char* lineptr[2] = { NULL, NULL };
	size_t n[2] = { 0, 0 };
	int counter = 0;

        while (getline(lineptr + counter, n + counter, stdin) != -1) {
		counter = 1 - counter;
	}
	if (lineptr[counter]) {
		printf("%s\n", lineptr[counter]);
	}

	if(lineptr[0]) free(lineptr[0]);
	if(lineptr[1]) free(lineptr[1]);

	return 0;
}
