#ifndef SHELL_H_
#define SHELL_H_

#include <stdlib.h>
#include <string.h>


#define YYSTYPE value_t
#define YY_DECL int yylex()

YY_DECL;

typedef struct value_t {
    enum _type_t {
        str_t,
        str_list_t,
        error_t,
    } _type;

    union _value_t {
        char* str;
        // TODO: str_list_t
    } _value;
} value_t;

void value_t_free(value_t value);
value_t value_t_str(const char*);

int yyerror(char*);

#endif  // SHELL_H_
