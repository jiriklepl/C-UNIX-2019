%token EXIT CD

%token PIPE SEMICOLON LBRACE RBRACE RARROW LARROW DRARROW NLINE

%token STRING

%code requires
{
    #include <stdio.h>

    #include "shell-common.h"
    YYSTYPE yylval;
}

%start request

%%

request: command_sequence NLINE
       | command_sequence SEMICOLON
       | NLINE
       | SEMICOLON
       | request request
       ;

string_list: STRING
           | string_list STRING
           ;

command_sequence: command
                | command_sequence PIPE command_sequence
                | LBRACE braced_commands_closed RBRACE
                ;

braced_commands_open: command_sequence
                    | braced_commands_closed command_sequence
                    ;

braced_commands_closed: NLINE
                      | SEMICOLON
                      | braced_commands_open NLINE
                      | braced_commands_open SEMICOLON
                      | braced_commands_closed NLINE
                      | braced_commands_closed SEMICOLON
                      ;

command: string_list
       | string_list RARROW STRING
       | string_list DRARROW STRING
       | string_list LARROW STRING
       ;
%%

int main(void) {
    return yyparse();
}

int yyerror(char *s) {
	printf("%s\n", s);

    return 127;
}
