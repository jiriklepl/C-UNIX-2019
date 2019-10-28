#include <stdio.h>
#include <assert.h>

int main(void) {
	short int number = 1;

	if (*((unsigned char*)&number) == 1) {
		printf("LITTLE ENDIAN\n");
	} else {
                printf("BIG ENDIAN\n");
        }

	assert(sizeof(number) == 2);

	return 0;
}
