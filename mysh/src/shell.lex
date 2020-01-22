%{
    #include "shell-common.h"
    #include "shell.tab.h"

    extern YYSTYPE yylval;
    extern size_t lineno;
%}

/* OPTIONs here */
%option noyywrap nounput noinput
%option never-interactive

/* MACROs here */
WS              [ \t\r]

/* STATEs here */

%%

%{
%}

#.*                               /* comment */

[A-Za-z0-9/\-._]+ {
    set_transfere_string(
        &yylval,
        yytext,
        yyleng);

    return STRING;
}


(\"([^"]|\\\")*\")+ {
    set_transfere_string(
        &yylval,
        yytext + 1,
        yyleng - 2);

    return STRING;
}


(\'([^']|\\\')*\')+ {
    set_transfere_string(
        &yylval,
        yytext + 1,
        yyleng - 2);

    return STRING;
}

"<"                               return LARROW;
">"                               return RARROW;
">>"                              return DRARROW;

"|"                               return PIPE;
";"                               return SEMICOLON;

{WS}+                             /* whitespace */

\n                                return NLINE;


<<EOF>>                           return EOF;

%%

void set_input_string(const char *in) {
    yy_scan_string(in);
}

void end_lexical_scan(void) {
    yy_delete_buffer(YY_CURRENT_BUFFER);
}
