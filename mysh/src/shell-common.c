#include "shell-common.h"

void clear_queue()
{
    while (!STAILQ_EMPTY(&queue_head)) {
        string *entry = STAILQ_FIRST(&queue_head);
        STAILQ_REMOVE_HEAD(&queue_head, _next);
        free(entry->_value);
        free(entry);
    }
}

void move_transfere_union(
    transfere_union *from,
    transfere_union *to)
{
    switch (to->_type = from->_type) {
        case TU_STRING:
            to->_val._str._beg = from->_val._str._beg;
            to->_val._str._len = from->_val._str._len;
        break;

        case TU_EMPTY:
        break;
    }

    from->_type = TU_EMPTY;
}

void set_transfere_string(
    transfere_union *tu_val,
    char *beg,
    size_t len)
{
    // clean-up:
    switch (tu_val->_type) {
        case TU_STRING:
            free(tu_val->_val._str._beg);
        break;

        case TU_EMPTY:
        break;
    }

    // setting the value here:
    if ((tu_val->_val._str._beg = malloc(len + 1))) {
        tu_val->_type = TU_STRING;
        memcpy(tu_val->_val._str._beg, beg, len);
        tu_val->_val._str._beg[len] = '\0';
        tu_val->_val._str._len = len;
    } else {
        tu_val->_type = TU_EMPTY;
    }
}
