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

"<"             return LARROW;
">"             return RARROW;
">>"            return DRARROW;

"|"             return PIPE;

"{"             return LBRACE;
"}"             return RBRACE;

{WS}+           /* whitespace */

[A-Za-z0-9]+ {
    yylval = value_t_str(yytext);

    return STRING;
}

<<EOF>>         return EOF;

%%
