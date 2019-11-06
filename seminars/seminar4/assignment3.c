#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

int main(void) {
    int count = 100;

    while (
        fork() == 0 &&
        printf("hi\n") >= 0 &&
        count-- != 0
    ) {
        sleep(1);
    }

    return 0;
}
