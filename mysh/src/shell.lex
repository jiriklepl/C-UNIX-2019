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
";;"            return SEMBICOLON;

"&"             return AMPERSAND; /* NOT SUPPORTED, JUST PA[RS]SING */
"$"             return DOLLAR; /* NOT SUPPORTED, JUST PA[RS]SING */

"{"             return LBRACE;
"}"             return RBRACE;

{WS}+           /* whitespace */

\n              return NLINE;

[A-Za-z0-9/-]+  return STRING;

<<EOF>>         return EOF;

%%

void set_input_string(const char* in) {
    yy_scan_string(in);
}

void end_lexical_scan(void) {
    yy_delete_buffer(YY_CURRENT_BUFFER);
}
