#ifndef SHELL_COMMON_H_
#define SHELL_COMMON_H_

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <readline/readline.h>
#include <readline/history.h>

#define YYSTYPE int
#define YY_DECL int yylex()
#define MYSH_PROMPT "mysh$ "

YY_DECL;

int yyerror(char*);

#endif  // SHELL_COMMON_H_
