#include "shell-common.h"

void value_t_free(value_t value) {
    if (value._type == str_t) {
        if (value._value.str != NULL) {
            free(value._value.str);
        }
    }
}

value_t value_t_str(const char* value) {
    value_t tmp = {
        ._type = str_t,
        ._value.str = malloc(strlen(value))
    };

    if (tmp._value.str != NULL) {
        strcpy(tmp._value.str, value);
    }

    return tmp;
}
