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
        error_t,
    } _type;

    union _value_t {
        char* str;
    } _value;
} value_t;

void value_t_free(value_t *value);
value_t value_t_assign(enum _type_t type, union _value_t value);

int yyerror(char*);

#endif  // SHELL_H_
