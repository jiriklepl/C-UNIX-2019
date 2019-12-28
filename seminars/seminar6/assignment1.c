#include <poll.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#define BUF_SIZE 256

int main(void) {
    struct pollfd pfd = { fd: 0, events: POLLIN, 0 };
    int rval;
    char* buf;
    buf = malloc(BUF_SIZE);

    while ((rval = poll(&pfd, 1, 5000)) > -1) {
        if (rval > 0) {
            ssize_t c = read(pfd.fd, buf, BUF_SIZE);
            write(1, buf, c);
        }
    }

    free(buf);
}
