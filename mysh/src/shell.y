%token EXIT CD

%token PIPE SEMICOLON LBRACE RBRACE RARROW LARROW DRARROW

%token STRING

%code requires
{
    #include <stdio.h>

    #include "shell-common.h"
    YYSTYPE yylval;
}

%start request
%%

request
    : command
    ;

command
    : STRING { printf("%s", $1._value.str); value_t_free($1); }
    | command STRING { printf("%s", $2._value.str); value_t_free($2); }
    ;
%%

int main(void) {
    return yyparse();
}

int yyerror(char *s) {
	printf("%s\n", s);

    return 127;
}
