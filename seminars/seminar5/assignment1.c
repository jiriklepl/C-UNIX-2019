#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <fcntl.h>


int check_file(int fd) {
    off_t len = lseek(fd, 0L, SEEK_END);
    lseek(fd, 0L, SEEK_SET);

    void* addr = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);

    if ((void *) -1 == addr) {
        printf("Could not map memory: %s\n", strerror(errno));
        return -1;
    }

    for (size_t i = 0, j = len; i < j--; ++i) {
        if (((char*)addr)[i] != ((char*)addr)[j]) {
            return 1;
        }
    }

    if (munmap(addr, len) == -1) {
        return -1;
    }

    return 0;
}

int main(int argc, const char* argv[]) {
    for (const char** arg = argv + 1; *arg != NULL; ++arg) {
        int fd = open(*arg, O_RDONLY);
        int is_palindrome;
        if(fd == -1) {
            printf("File cannot be opened...\n");
        } else if ((is_palindrome = check_file(fd)) == 1) {
            printf("It is not a palindrome :(\n");
        } else if(is_palindrome == 0) {
            printf("Yes, awesome! It is a palindrome :)\n");
        }

        close(fd);
    }
    
    return 0;
}