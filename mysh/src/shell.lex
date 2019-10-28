%{
    #include "shell.h"
    #include "shell.tab.h"

    extern YYSTYPE yylval;
%}

/* OPTIONs here */
%option noyywrap nounput noinput
%option never-interactive

/* MACROs here */
WS              [ \t\r]

/* STATEs here */
%x              STRING



%%

%{
%}

"<"             return LARROW;
">"             return RARROW;
">>"            return DRARROW;

{WS}+           /* whitespace */


%%