#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>


int main(void) {
    printf("hello\n");
    fork();
    printf("how are you?\n");
    fork();
    printf("why are you?\n");
    fork();
    sleep(20);
    printf("bye\n");

    return 0;
}
