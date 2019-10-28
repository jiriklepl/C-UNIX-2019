#include <stdio.h>

void func(const char ** const argv) {
	if (*argv) {
		printf("%s\n", *argv);
		return func(argv + 1);
	} else {
		return;
	}
}

int main(int argc, const char* argv[]) {
	printf("for:\n");
	for (int i = 1; i < argc; i++) {
		printf("%s\n", argv[i]);
	}
	
	printf("while:\n");
	const char** ptr = argv;
	while (*(++ptr)) {
                printf("%s\n", *ptr);
        }

	printf("func:\n");
	func(argv + 1);

	return 0;

}
