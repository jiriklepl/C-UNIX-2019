%token EXIT CD

%token PIPE SEMICOLON LBRACE RBRACE

%token STRING

%start request
%%

request
    : command
    ;

command
    : STRING
    ;
%%

int main(void) {
    return yyparse();
}