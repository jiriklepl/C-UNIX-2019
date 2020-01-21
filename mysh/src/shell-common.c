#include "shell-common.h"

void clear_queue() {
    while (!STAILQ_EMPTY(&queue_head)) {
        queue_union *entry = STAILQ_FIRST(&queue_head);
        STAILQ_REMOVE_HEAD(&queue_head, _next);

        switch (entry->_type) {
            case QU_STRING:
            case QU_RARROW:
            case QU_DRARROW:
            case QU_LARROW:
                free(entry->_val._str);
            break;

            case QU_EMPTY:
            case QU_PIPE:
            break;
        }

        free(entry);
    }
}

queue_union *enqueue_new(transfere_union *from, enum qu_type type) {
    queue_union *entry;

    if ((entry = malloc(sizeof(queue_union))) == NULL) {
        return NULL;
    }

    switch (entry->_type = type) {
        case QU_STRING:
        case QU_RARROW:
        case QU_DRARROW:
        case QU_LARROW:
            if ((entry->_val._str = malloc(from->_val._str._len + 1)) == NULL) {
                free(entry);

                return NULL;
            }

            memcpy(
                entry->_val._str,
                from->_val._str._beg,
                from->_val._str._len);

            entry->_val._str[from->_val._str._len] = '\0';
        break;

        case QU_EMPTY:
        case QU_PIPE:
        break;
    }

    STAILQ_INSERT_TAIL(&queue_head, entry, _next);

    return entry;
}

void move_transfere_union(
    transfere_union *from,
    transfere_union *to
) {
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
    size_t len
) {
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
