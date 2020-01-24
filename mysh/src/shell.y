%token STRING
%token PIPE
%token SEMICOLON
%token LBRACE
%token RBRACE
%token RARROW
%token LARROW
%token DRARROW
%token NLINE
%token AMPERSAND
%token DOLLAR

%token END 0 "end of file"

%define parse.error verbose

%code requires {
    #include "shell-common.h"
}

%code {
    void do_enqueue(enum tu_type type);
    void run_pipeline(void);
}

%start request

%%

request:
    open_request
    | closed_request
    ;

open_request:
    closed_request command_sequence { run_pipeline(); }
    ;

closed_request:
    | SEMICOLON
    | open_request SEMICOLON
    | request NLINE { ++lineno; }
    ;

redirection:
    RARROW STRING { do_enqueue(QU_RARROW); }
    | DRARROW STRING { do_enqueue(QU_DRARROW); }
    | LARROW STRING { do_enqueue(QU_LARROW); }
    ;

redirection_list:
    | redirection_list redirection
    ;

command:
    redirection_list STRING { do_enqueue(QU_STRING); }
    | command STRING { do_enqueue(QU_STRING); }
    | command redirection
    ;

command_sequence:
    { clear_queue(); } command
    | command_sequence PIPE { do_enqueue(QU_PIPE); } command
    ;
%%
