%token EXIT CD

%token PIPE SEMICOLON SEMBICOLON LBRACE RBRACE RARROW LARROW DRARROW NLINE AMPERSAND DOLLAR

%token END 0 "end of file"

%token STRING

%code requires
{
    #include <stdio.h>

    #include "shell-common.h"
    YYSTYPE yylval;
}

%start request

%%

request:
    command_sequence
    ;

command:
    STRING
    | command STRING
    | command RARROW STRING
    | command DARROW STRING
    | command LARROW STRING
    ;

command_sequence:
    command
    | command_sequence PIPE command
    ;
%%

void set_input_string(const char* in);
void end_lexical_scan(void);

/* This function parses a string */
int parse_line() {
    char* in = readline(MYSH_PROMPT);
    set_input_string(in);
    int rv = yyparse();
    end_lexical_scan();
    return rv;
}

int main(void) {
    return parse_line();
}

int yyerror(char *s) {
	printf("%s\n", s);

    return 127;
}
