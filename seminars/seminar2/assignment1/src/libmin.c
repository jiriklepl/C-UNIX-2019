#include <stdlib.h>

#include "libmin.h"

int min(int a[], ssize_t len) {
    len /= sizeof(int);
    int min = a[--len];
    
    while (len--) {
        min = (min > a[len])
            ? a[len]
            : min;
    }

    return min;
}