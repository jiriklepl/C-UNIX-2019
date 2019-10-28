#include "shell.h"

void value_t_free(value_t *value) {
    if (value->_type == str_t) {
        free(value->_value.str);
    }
}

value_t value_t_assign(enum _type_t type, union _value_t value) {
    value_t tmp;
    switch (type) {
        case str_t:
            tmp._type = type;
            tmp._value.str = malloc(sizeof(union _value_t));

            if (tmp._value.str != NULL) {
                strcpy(tmp._value.str, value.str);
            }

            break;
        case error_t:
        default:
            tmp._type = error_t;

            break;
    }

    return tmp;
}