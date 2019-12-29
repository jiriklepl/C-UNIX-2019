%token STRING
%token PIPE
%token SEMICOLON
%token SEMBICOLON
%token LBRACE
%token RBRACE
%token RARROW
%token LARROW
%token DRARROW
%token NLINE
%token AMPERSAND
%token DOLLAR

%token END 0 "end of file"

%code requires
{
    #include <stdio.h>

    #include "shell-common.h"

    YYSTYPE yylval;
}

%start request

%%

request:
    | command_sequence SEMICOLON request
    ;

command:
    STRING
    | RARROW STRING STRING
    | DRARROW STRING STRING
    | LARROW STRING STRING
    | command STRING
    | command RARROW STRING
    | command DRARROW STRING
    | command LARROW STRING
    ;

command_sequence:
    command
    | command_sequence PIPE command
    ;
%%

void set_input_string(const char* in);
void end_lexical_scan(void);
char* input_line = NULL;

/* This function parses a string */

int parse_line()
{
    set_input_string(input_line);
    int rv = yyparse();
    end_lexical_scan();

    return rv;
}

void intHandler(int sig)
{
    signal(sig, SIG_IGN);
    rl_point = 0;
    rl_delete_text(0, rl_end);
    rl_reset_line_state();
    printf("\n");
    rl_redisplay();
    signal(SIGINT, intHandler);
}

int parse_loop()
{
    int rv = 1;
    while (1) {
        input_line = readline(MYSH_PROMPT);

        if (input_line == NULL) {
            rv = 00;
            break;
        }

        rv = parse_line();
    }

    return rv;
}

int main(void)
{
    signal(SIGINT, intHandler);
    STAILQ_INIT(&queue_head);
    return parse_loop();
}

int yyerror(char *s)
{
	printf("%s\n", s);

    return 127;
}
