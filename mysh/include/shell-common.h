#ifndef SHELL_COMMON_H_
#define SHELL_COMMON_H_

#define _DEFAULT_SOURCE

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <err.h>
#include <stdbool.h>

#include <linux/limits.h>

#include <sys/queue.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

#include <readline/readline.h>
#include <readline/history.h>

#define YYSTYPE transfere_union
#define YY_DECL int yylex()
#define MYSH_PROMPT "mysh:%s$ "

int yyerror(const char *);

typedef struct queue_union {
    enum qu_type {
        QU_EMPTY,
        QU_STRING,
        QU_RARROW,
        QU_DRARROW,
        QU_LARROW,
        QU_PIPE
    } _type;

    union {
        char *_str;
    } _val;

    STAILQ_ENTRY(queue_union) _next;
} queue_union;

STAILQ_HEAD(string_queue, queue_union) queue_head;

void clear_queue();
queue_union *enqueue_new();

/*
 * this struct is for transfering data between the lexer and
 * bison, lexer being responsible for clean-up
 */
typedef struct transfere_union {
    enum tu_type {
        TU_EMPTY,
        TU_STRING
    } _type;

    union {
        struct {
            char *_beg;
            size_t _len;
        } _str;
    } _val;
} transfere_union;

void move_transfere_union(
    transfere_union *from,
    transfere_union *to);

void set_transfere_string(
    transfere_union *tu_val,
    char *beg,
    size_t len);


YY_DECL;

void panic_exit(int);

#endif  // SHELL_COMMON_H_
