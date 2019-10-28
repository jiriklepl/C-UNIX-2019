#include <stdio.h>


int main(void) {
    void *pointer = &pointer;
    printf("Pointer address: %p\n", &pointer);
    printf("Pointer value:   %p\n", pointer);
    return 0;
}
