#include <stdio.h>
#include <err.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, const char* argv[]) {
    if (argc != 2) {
        errx(1, "Not the right number of arguments %d\n", argc);
    }

    int fd = open(argv[1], O_RDONLY);

    if (fd == -1) {
        errx(2, "Cannot open the file %s\n", argv[1]);
    }

    int bytes_read;
    char buffer[128];

    while ((bytes_read = read(fd, buffer, 127)) > 0) {
        buffer[bytes_read] = 0;
        printf("%s", buffer);
    }

    if (bytes_read < 0) {
        errx(3, "Error while reading the file");
    }

    close(fd);
    return 0;
}
