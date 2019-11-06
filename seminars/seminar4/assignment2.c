#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(void) {
    execlp("vim", "vim", "/etc/passwd", NULL);
    return 0;
}
