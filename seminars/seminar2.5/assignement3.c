#include <stdio.h>
#include <err.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define BUFFER_SIZE 128


int main(int argc, const char* argv[]) {
    if (argc != 2) {
        errx(1, "Not the right number of arguments %d\n", argc);
    }

    int fd = open(argv[1], O_RDONLY);

    if (fd == -1) {
        errx(2, "Cannot open the file %s\n", argv[1]);
    }

    int bytes_read;
    char
        buffer[128],
        *where = buffer,
        *last = buffer,
        *begin = buffer,
        *end = buffer + BUFFER_SIZE;
    char doend = 0;

    while (!doend) {
        if (begin < end) {
            if ((bytes_read = read(fd, begin, end - begin)) <= 0) {
                break;
            }

            if (bytes_read < end - begin) {
                doend = 1;
                end = begin + bytes_read;
            }
        } else {
            if (
                (bytes_read = read(
                    fd,
                    begin,
                    buffer + BUFFER_SIZE - begin)
                ) < 0
            ) {
                break;
            }

            if (bytes_read < buffer + BUFFER_SIZE - begin) {
                doend = 1;
            }

            if (
                bytes_read == buffer + BUFFER_SIZE - begin &&
                (bytes_read = read(fd, buffer, end - buffer)) < 0
            ) {
                break;
            }

            if (bytes_read < end - buffer) {
                doend = 1;
                end = buffer + bytes_read;
            }
        }

        for (where = begin; where != end; ++where) {
            if (where == buffer + BUFFER_SIZE) {
                where = buffer;
            }

            if (*where == '\n') {
                if (last < where) {
                    write(STDOUT_FILENO, last, where - last);
                } else {
                    write(STDOUT_FILENO, last, buffer + BUFFER_SIZE - last);
                    write(STDOUT_FILENO, buffer, where - buffer);
                }

                last = where;
                sleep(1);
            }
        }

        begin = end;
        end = last;
    }

    if (bytes_read < 0) {
        errx(3, "Error while reading the file");
    }

    close(fd);
    return 0;
}
