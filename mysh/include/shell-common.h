#ifndef SHELL_COMMON_H_
#define SHELL_COMMON_H_

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <signal.h>
#include <sys/queue.h>

#include <readline/readline.h>
#include <readline/history.h>

#define YYSTYPE transfere_union
#define YY_DECL int yylex()
#define MYSH_PROMPT "mysh$ "

int yyerror(char*);

struct string {
    char*  _value;
};

STAILQ_HEAD(string_queue, string) queue_head;


/* this struct is for transfering data between the lexer and
 * bison, lexer being responsible for clean-up
 */
typedef struct transfere_union {
    enum {
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

#endif  // SHELL_COMMON_H_
