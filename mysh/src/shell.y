%token STRING
%token PIPE
%token SEMICOLON
%token LBRACE
%token RBRACE
%token RARROW
%token LARROW
%token DRARROW
%token NLINE
%token AMPERSAND
%token DOLLAR

%token END 0 "end of file"

%define parse.error verbose

%code requires {
    #include "shell-common.h"
}

%code {
    struct sigaction int_action, chld_action;
    YYSTYPE yylval;
    size_t lineno = 1;
    char *input_line = NULL;
    int is_interactive = 1;

    extern FILE *yyin;

    int last_return_value;
    char *cwd;
    int redisplay = 1;

    void use_prefix();
    int switch_store_cwd();

    void set_input_string(const char *);
    void end_lexical_scan(void);

    void intHandler(int sig);
    void chldHandler(int sig);
}

%start request

%%

request:
    open_request
    | closed_request
    ;

open_request:
    closed_request command_sequence
    ;

closed_request:
    | SEMICOLON
    | open_request SEMICOLON
    | request NLINE { ++lineno; }
    ;

command_bit:
    STRING {
        string *entry;

        if ((entry = malloc(sizeof(string)))) {
            if ((entry->_value = malloc(yylval._val._str._len + 1))) {
                memcpy(
                    entry->_value,
                    yylval._val._str._beg,
                    yylval._val._str._len);

                entry->_value[yylval._val._str._len] = '\0';
                STAILQ_INSERT_TAIL(&queue_head, entry, _next);
            } else {
                free(entry);
                end_lexical_scan();
                panic_exit(254);
            }
        } else {
            end_lexical_scan();
            panic_exit(254);
        }
    }
    | RARROW STRING
    | DRARROW STRING
    | LARROW STRING
    ;

command:
    { clear_queue(); } command_bit
    | command command_bit
    ;

command_sequence:
    command {
        string *entry;
        char **argv;
        size_t i = 0;

        STAILQ_FOREACH(entry, &queue_head, _next) {
            ++i;
        }

        if ((argv = malloc(sizeof(char *) * (i + 1)))) {
            i = 0;

            STAILQ_FOREACH(entry, &queue_head, _next) {
                argv[i] = entry->_value;
                entry->_value = NULL;
                ++i;
            }

            argv[i] = NULL;

            if (strcmp(*argv, "cd") == 0) {
                if (i == 1) {
                    // cd home
                    if ((last_return_value = chdir(getenv("HOME"))) == 0) {
                        if (switch_store_cwd() == -1) {
                            end_lexical_scan();
                            panic_exit(254);
                        }
                    } else {
                        use_prefix();

                        fprintf(
                            stderr,
                            "Cannot go to $HOME: %s\n",
                            getenv("HOME"));
                    }
                } else if (i > 2) {
                    // too many arguments
                        use_prefix();

                        fprintf(
                            stderr,
                            "cd: too many arguments\n");

                        last_return_value = 1;
                } else if (strcmp(argv[1], "-") == 0) {
                    // cd to OLDPWD (swap with PWD)
                    if ((last_return_value = chdir(getenv("OLDPWD"))) == 0) {
                        if (switch_store_cwd() == -1) {
                            end_lexical_scan();
                            panic_exit(254);
                        }

                        printf("%s\n", cwd);
                    } else {
                        use_prefix();

                        fprintf(
                            stderr,
                            "Cannot go to $OLDPWD: %s\n",
                            getenv("OLDPWD"));
                    }
                } else {
                    if ((last_return_value = chdir(argv[1])) == 0) {
                        if (switch_store_cwd() == -1) {
                            end_lexical_scan();
                            panic_exit(254);
                        }
                    } else {
                        use_prefix();

                        fprintf(
                            stderr,
                            "Cannot go to %s\n",
                            getenv("OLDPWD"));
                    }
                }
            } else if (strcmp(*argv, "exit") == 0) {
                exit(last_return_value);
            } else {
                pid_t cpid;

                cpid = fork();

                if (cpid == -1) {
                    perror("fork");
                    exit(EXIT_FAILURE);
                } else if (cpid == 0) {
                    // child

                    if (execvp(*argv, argv)) {
                        use_prefix();

                        fprintf(
                            stderr,
                            "%s - No such file or directory\n",
                            *argv);

                        exit(127);
                    }
                } else {
                    // parent
                    redisplay = 0;
                    pause();
                }
            }

            while (i-- > 0) {
                free(argv[i]);
            }

            free(argv);
            redisplay = 1;
        } else {
            end_lexical_scan();
            panic_exit(254);
        }
    }
    | command_sequence PIPE command
    ;
%%


void panic_exit(int code) {
    clear_queue();
    exit(code);
}

/* This function parses a string */
int parse_line() {
    set_input_string(input_line);
    int rv = yyparse();
    end_lexical_scan();

    return rv;
}

void intHandler(int sig) {
    // bash does that
    last_return_value = 128 + sig;

    if (redisplay) {
        rl_point = 0;
        rl_delete_text(0, rl_end);
        rl_reset_line_state();
        printf("\n");
        rl_redisplay();
    }
}

void chldHandler(int sig) {
    pid_t w;
    int wstatus;

    last_return_value = 128 + sig;

    if ((w = waitpid(-1, &wstatus, WNOHANG))) {
        if (w == -1) {
            perror("waitpid");
            panic_exit(EXIT_FAILURE);
        }

        if (WIFEXITED(wstatus)) {
            last_return_value = WEXITSTATUS(wstatus);
        } else if (WIFSIGNALED(wstatus)) {
            use_prefix();

            fprintf(
                stderr,
                "Killed by signal %d\n",
                WTERMSIG(wstatus));

            last_return_value = WTERMSIG(wstatus) + 128;
        } else if (WIFSTOPPED(wstatus)) {
            use_prefix();

            fprintf(
                stderr,
                "Stopped by signal %d\n",
                WSTOPSIG(wstatus));

            last_return_value = WSTOPSIG(wstatus) + 128;
        }
    }
}

int parse_loop() {
    while (1) {
        char *prompt = NULL;
        int len = snprintf(NULL, 0, MYSH_PROMPT, cwd);

        if ((prompt = malloc(len + 1))) {
            snprintf(prompt, len + 1, MYSH_PROMPT, cwd);
        } else {
            panic_exit(254);
        }

        input_line = readline(prompt);

        free(prompt);

        if (input_line == NULL) {
            clear_queue();
            break;
        }

        if (
            strlen(input_line) > 0 &&
            input_line[0] != ' '
        ) {
            add_history(input_line);
        }

        if (parse_line()) {
            last_return_value = 254;
        }

        free(input_line);
        clear_queue();
    }

    rl_clear_history();

    return last_return_value;
}

int parse_string_loop(char *from_string) {
    if (from_string == NULL) {
        last_return_value = 127;
    } else {
        input_line = from_string;

        if (parse_line()) {
            last_return_value = 254;
        }

        free(input_line);
    }

    clear_queue();

    return last_return_value;
}

int parse_file_loop(char *fname) {
    FILE *fh = fopen(fname, "r");

    if (fh == NULL) {
        errx(254, "Cannot open the file %s\n", fname);
    }

    yyin = fh;

    if (yyparse()) {
        last_return_value = 254;
    }

    fclose(fh);
    clear_queue();

    return last_return_value;
}

int main(int argc, char *argv[]) {
    struct {
        int c;
        char *c_val;
    } opts = { .c = 0 };

    int opt;

    while ((opt = getopt(argc, argv, "c:")) != -1) {
        switch (opt) {
            case 'c':
                if (
                    (opts.c = strlen(optarg)) > 0 &&
                    (opts.c_val = malloc(opts.c + 1))
                ) {
                    strcpy(opts.c_val, optarg);
                } else {
                    exit(254);
                }

                opts.c = 1;
            break;
        }
    }

    int_action.sa_handler = intHandler;
    sigemptyset(&int_action.sa_mask);
    int_action.sa_flags = 0;
    sigaction(SIGINT, &int_action, NULL);

    chld_action.sa_handler = chldHandler;
    sigemptyset(&chld_action.sa_mask);
    chld_action.sa_flags = 0;
    sigaction(SIGCHLD, &chld_action, NULL);

    STAILQ_INIT(&queue_head);

    cwd = NULL;

    if (switch_store_cwd() == -1) {
        panic_exit(254);
    }

    if (opts.c == 1) {
        return parse_string_loop(opts.c_val);
    } else if (argc == 1) {
        return parse_loop();
    } else {
        is_interactive = 0;
        return parse_file_loop(argv[optind]);
    }
}

void use_prefix() {
    if (!is_interactive) {
        fprintf(stderr, "Line %zu: ", lineno);
    }
}

int switch_store_cwd() {
    char *new_cwd;

    if (cwd == NULL) {
        if (unsetenv("OLDPWD") == -1) {
            return -1;
        }
    } else if (setenv("OLDPWD", cwd, 1) == -1) {
        return -1;
    }

    if ((new_cwd = getcwd(NULL, 0)) == NULL) {
        return -1;
    }

    if (setenv("PWD", new_cwd, 1) == -1) {
        free(new_cwd);
        return -1;
    }

    free(new_cwd);
    cwd = getenv("PWD");

    return 0;
}

int yyerror(const char *s) {
    use_prefix();
	fprintf(stderr, "%s\n", s);

    return 127;
}
