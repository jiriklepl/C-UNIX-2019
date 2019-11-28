#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
    #include <sys/wait.h>

#define N 20

int main(void) {

    printf("%i", getpid());
    size_t i = 0;

    pid_t pid, me;
    int status;

dochildren:
    while ((me = fork()) > 0 && i++ < N) {
        // parent loop

        sleep(1);
    }
    sleep(1);

    if (me == 0 && (pid = wait(&status))) {
        printf("Terminated %i with %i exit", (int)pid, WEXITSTATUS(status));
        goto dochildren;
    }

    for (;;) {
        // child loop
        pause();
    }

    return 0;
}
