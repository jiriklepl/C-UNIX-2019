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

void enqueue_new(
    transfere_union value,
    enum qu_type type
) {
    queue_union *entry;

    if ((entry = malloc(sizeof(queue_union))) == NULL) {
        perror("queue error");
        exit(GENERAL_ERROR);
    }

    switch (entry->_type = type) {
        case QU_STRING:
        case QU_RARROW:
        case QU_DRARROW:
        case QU_LARROW:
            if (
                (entry->_val._str = malloc(value._val._str._len + 1)) == NULL
            ) {
                perror("queue error");
                exit(GENERAL_ERROR);
            }

            memcpy(
                entry->_val._str,
                value._val._str._beg,
                value._val._str._len);

            entry->_val._str[value._val._str._len] = '\0';
        break;

        case QU_EMPTY:
        case QU_PIPE:
        break;
    }

    STAILQ_INSERT_TAIL(&queue_head, entry, _next);
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
