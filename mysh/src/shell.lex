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

#.*                               /* comment */

([A-Za-z0-9/-]|(\"([^"]|\\\")*\")|(\'([^']|\\\')*\'))+ {
    /* TODO: might split into four functions */
    set_transfere_string(
        &yylval,
        yytext + ((yytext[0] == '"' ||
            yytext[0] == '\'')
            ? 1
            : 0),
        yyleng - ((yytext[yyleng - 1] == '"' ||
            yytext[yyleng - 1] == '\'')
            ? 1
            : 0));
    return STRING;
}

"<"                               return LARROW;
">"                               return RARROW;
">>"                              return DRARROW;

"|"                               return PIPE;
";"                               return SEMICOLON;
";;"                              return SEMBICOLON;

"&"                               return AMPERSAND;
    /* NOT SUPPORTED, JUST PA[RS]SING */
"$"                               return DOLLAR;
    /* NOT SUPPORTED, JUST PA[RS]SING */

"{"                               return LBRACE;
    /* NOT SUPPORTED, JUST PA[RS]SING */

"}"                               return RBRACE;
    /* NOT SUPPORTED, JUST PA[RS]SING */

{WS}+                             /* whitespace */

\n                                return NLINE;


<<EOF>>                           return EOF;

%%

void set_input_string(const char *in)
{
    yy_scan_string(in);
}

void end_lexical_scan(void)
{
    yy_delete_buffer(YY_CURRENT_BUFFER);
}
