%{
    #include "shell-common.h"
    #include "shell.tab.h"

    extern YYSTYPE yylval;
%}

/* OPTIONs here */
%option noyywrap nounput noinput
%option always-interactive

/* MACROs here */
WS              [ \t\r]

/* STATEs here */
%%

%{
%}

cd              return CD;
exit            return EXIT;

"<"             return LARROW;
">"             return RARROW;
">>"            return DRARROW;

"|"             return PIPE;
";"             return SEMICOLON;

"{"             return LBRACE;
"}"             return RBRACE;

{WS}+           /* whitespace */

\n              return NLINE;

[A-Za-z0-9]+    return STRING;

<<EOF>>         return EOF;

%%
