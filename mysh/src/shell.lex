%{
    #include "shell.tab.h"
%}

/* OPTIONs here */

/* MACROs here */

/* STATEs here */

WS              [ \t\r]

%x              STRING

%%

%{
%}

"<"
">"
">>"
""

{WS}+           /* whitespace */


%%