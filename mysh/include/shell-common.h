#ifndef SHELL_COMMON_H_
#define SHELL_COMMON_H_

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <signal.h>
#include <sys/queue.h>

#include <readline/readline.h>
#include <readline/history.h>

#define YY_DECL int yylex()
#define MYSH_PROMPT "mysh$ "

int yyerror(char*);

struct string {
    char*  _value;
};

STAILQ_HEAD(string_queue, string) queue_head;

struct string_queue *queue_headp;

YY_DECL;

#endif  // SHELL_COMMON_H_
