%token EXIT CD

%token PIPE SEMICOLON LBRACE RBRACE RARROW LARROW DRARROW

%token STRING

%code requires
{
    #include "shell.h"
    YYSTYPE yylval;
}

%start request
%%

request
    : command
    ;

command
    : STRING
    ;
%%

#include <stdio.h>

int main(void) {
    return yyparse();
}

int yyerror(char *s) {
	printf("%s\n", s);

    return 127;
}
