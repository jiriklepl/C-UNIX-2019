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

request: command_sequence
       ;

string_list: STRING
           | string_list STRING
           ;

command_sequence: command
                | command_sequence PIPE command
                ;

command: string_list
       | string_list RARROW STRING
       | string_list DRARROW STRING
       | string_list LARROW STRING
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
