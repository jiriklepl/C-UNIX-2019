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

    void use_prefix(void);
    int switch_store_cwd(void);

    void set_input_string(const char *);
    void end_lexical_scan(void);

    void intHandler(int sig);
    void chldHandler(int sig);

    int parse_line(void);
    int parse_loop(void);
    int parse_string_loop(char *from_string);
    int parse_file_loop(char *fname);

    struct prgv_t {
        /*
            * output and input, NULL represents there is no redirection
            * (pipe is still considered NULL)
            */
        char *_out, *_in;

        // true if >>, false if >, nondeterministic otherwise
        bool _append;
    };

    void open_child(
        char *argv[],
        struct prgv_t *prgv);
}

%start request

%%

request:
    open_request
    | closed_request
    ;

open_request:
    closed_request command_sequence {
        queue_union *entry;

        char **argv;
        struct prgv_t *prgv;

        size_t argc = 0;
        size_t prgc = 1;

        STAILQ_FOREACH(entry, &queue_head, _next) {
            switch (entry->_type) {
                case QU_STRING:
                    ++argc;
                break;

                case QU_RARROW:
                case QU_DRARROW:
                case QU_LARROW:
                    // these just modify in/out
                break;

                case QU_PIPE:
                    ++prgc;
                break;

                case QU_EMPTY:
                break;
            }
        }

        if (
            (argv = malloc(sizeof(char *) * (argc + prgc + 1))) == NULL ||
            (prgv = malloc(sizeof(struct prgv_t) * prgc)) == NULL
        ) {
            end_lexical_scan();
            panic_exit(254);
        }

        for (size_t i = 0; i < prgc; ++i) {
            prgv[i]._out = prgv[i]._in = NULL;
        }

        argc = 1;
        prgc = 0;

        argv[0] = NULL;

        STAILQ_FOREACH(entry, &queue_head, _next) {
            switch (entry->_type) {
                case QU_STRING:
                    argv[argc + prgc] = entry->_val._str;
                    entry->_val._str = NULL;
                    ++argc;
                break;

                case QU_RARROW:
                    // TODO: maybe function
                    free(prgv[prgc]._out);
                    prgv[prgc]._out = entry->_val._str;
                    entry->_val._str = NULL;
                    prgv[prgc]._append = false;
                break;

                case QU_DRARROW:
                    free(prgv[prgc]._out);
                    prgv[prgc]._out = entry->_val._str;
                    entry->_val._str = NULL;
                    prgv[prgc]._append = true;
                break;

                case QU_LARROW:
                    free(prgv[prgc]._in);
                    prgv[prgc]._in = entry->_val._str;
                    entry->_val._str = NULL;
                break;

                case QU_PIPE:
                    argv[argc + prgc] = NULL;
                    ++prgc;
                break;

                case QU_EMPTY:
                break;
            }
        }

        argv[argc + prgc] = NULL;

        int pd[3] = {0, 1, -1};

        size_t actual_argc = argc;
        size_t actual_prgc = prgc + 1;

        --argc;

        pid_t cpid;

        while (prgc != 0) {
            // skip the topmost null on argv array and find the next one
            while (argv[argc + prgc] != NULL) {
                --argc;
            }

            if (pipe(pd) == -1) {
                perror("pipe");
                end_lexical_scan();
                panic_exit(254);
            }

            switch (cpid = fork()) {
                case -1:
                    perror("fork");
                    end_lexical_scan();
                    panic_exit(254);
                break;

                case 0:
                    if (
                        ((pd[2] != -1) && (
                            dup2(pd[2], STDOUT_FILENO) == -1 ||
                            close(pd[2]) == -1
                        )) ||
                        dup2(pd[0], STDIN_FILENO) == -1 ||
                        close(pd[0]) == -1 ||
                        close(pd[1]) == -1
                    ) {
                        perror("fork");
                        end_lexical_scan();
                        panic_exit(254);
                    }

                    open_child(argv + argc + prgc + 1, prgv + prgc);

                    // we get here iff first argument here is either cd or exit
                    exit(last_return_value);
                break;

                default:
                    close(pd[0]);

                    if (pd[2] != -1) {
                        close(pd[2]);
                    }


                    pd[2] = pd[1];
                break;
            }

            --prgc;
        }

        if (
            strcmp(*(argv + 1), "cd") != 0 &&
            strcmp(*(argv + 1), "exit") != 0
        ) {
            cpid = fork();
        } else {
            close(pd[2]);
            pd[2] = -1;
            cpid = 0;
        }

        switch (cpid) {
            case -1:
                perror("fork");
                end_lexical_scan();
                panic_exit(254);
            break;

            case 0:
                if (pd[2] != -1) {
                    if (
                        dup2(pd[2], STDOUT_FILENO) == -1 ||
                        close(pd[2]) == -1
                    ) {
                        perror("fork");
                        end_lexical_scan();
                        panic_exit(254);
                    }
                }

                open_child(argv + 1, prgv + prgc);
            break;

            default:
                if (pd[2] != -1) {
                    close(pd[2]);
                }

                redisplay = 0;
                pause();
            break;
        }

        for (size_t i = 0; i < actual_argc + actual_prgc; ++i) {
            free(argv[i]);
        }

        for (size_t i = 0; i < actual_prgc; ++i) {
            free(prgv[i]._in);
            free(prgv[i]._out);
        }

        free(argv);
        free(prgv);
        redisplay = 1;
    }
    ;

closed_request:
    | SEMICOLON
    | open_request SEMICOLON
    | request NLINE { ++lineno; }
    ;

command_bit:
    STRING {
        if (enqueue_new(&yylval, QU_STRING) == NULL) {
            end_lexical_scan();
            panic_exit(254);
        }
    }
    | RARROW STRING {
        if (enqueue_new(&yylval, QU_RARROW) == NULL) {
            end_lexical_scan();
            panic_exit(254);
        }
    }
    | DRARROW STRING {
        if (enqueue_new(&yylval, QU_DRARROW) == NULL) {
            end_lexical_scan();
            panic_exit(254);
        }
    }
    | LARROW STRING {
        if (enqueue_new(&yylval, QU_LARROW) == NULL) {
            end_lexical_scan();
            panic_exit(254);
        }
    }
    ;

command:
    command_bit
    | command command_bit
    ;

command_sequence:
    { clear_queue(); } command
    | command_sequence PIPE {
        if (enqueue_new(&yylval, QU_PIPE) == NULL) {
            end_lexical_scan();
            panic_exit(254);
        }
    } command
    ;
%%

void open_child(
    char *argv[],
    struct prgv_t *prgv
) {
    if (strcmp(*argv, "cd") == 0) {
        if (argv[1] == NULL) {
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
        } else if (argv[2] != NULL) {
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
                    argv[1]);
            }
        }
    } else if (strcmp(*argv, "exit") == 0) {
        exit(last_return_value);
    } else {
        if (prgv->_in) {
            int fd = open(prgv->_in, O_RDONLY);

            if (
                fd == -1 ||
                dup2(fd, STDIN_FILENO) == -1 ||
                close(fd) == -1
            ) {
                perror("failed opening input");
                exit(127);
            }
        }

        if (prgv->_out) {
            int fd;

            mode_t mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;

            if(prgv->_append) {
                fd = open(prgv->_out, O_APPEND | O_CREAT | O_WRONLY, mode);
            } else {
                fd = open(prgv->_out, O_WRONLY | O_CREAT | O_TRUNC, mode);
            }

            if (
                fd == -1 ||
                dup2(fd, STDOUT_FILENO) == -1 ||
                close(fd) == -1
            ) {
                perror("failed opening output");
                exit(127);
            }
        }

        if (execvp(*argv, argv)) {
            use_prefix();

            fprintf(
                stderr,
                "%s - No such file or directory\n",
                *argv);

            exit(127);
        }
    }
}

void panic_exit(int code) {
    clear_queue();
    exit(code);
}

/* This function parses a string */
int parse_line(void) {
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

    assert(SIGCHLD == sig);

    while ((w = waitpid(-1, &wstatus, WNOHANG)) != -1) {
        if (w == -1) {
            perror("waitpid");
            panic_exit(EXIT_FAILURE);
        }

        int s_code;
        char s_chars[22];
        char *message;
        char *beg;
        size_t length = 1;
        s_chars[sizeof(s_chars) - 1] = '\n';

        if (WIFEXITED(wstatus)) {
            last_return_value = WEXITSTATUS(wstatus);

            continue;
        } else if (WIFSIGNALED(wstatus)) {
            message = "Killed by signal ";
            s_code = WTERMSIG(wstatus);
        } else if (WIFSTOPPED(wstatus)) {
            message = "Stopped by signal ";
            s_code = WSTOPSIG(wstatus);
        } else {
            message = "";
            s_code = 127;
        }

        last_return_value = s_code + 128;

        do {
            s_chars[sizeof(s_chars) - ++length] = (char)('0' + (s_code % 10));
        } while ((s_code /= 10) != 0);

        beg = s_chars + sizeof(s_chars) - length;
        beg -= (length = strlen(message));

        memcpy(beg, message, length);

        write(STDERR_FILENO, beg, s_chars + sizeof(s_chars) - beg);
    }
}

int parse_loop(void) {
    while (1) {
        char *prompt = NULL;
        int len = snprintf(NULL, 0, MYSH_PROMPT, cwd);

        if (len < 0) {
            panic_exit(254);
        } else if ((prompt = malloc(len + 1))) {
            snprintf(prompt, len + 1, MYSH_PROMPT, cwd);
        } else {
            panic_exit(254);
        }

        input_line = readline(prompt);

        free(prompt);

        if (input_line == NULL) {
            clear_queue();
            printf("\n");

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
            case 'c': {
                size_t len;

                if (
                    (len = strlen(optarg)) > 0 &&
                    (opts.c_val = malloc(len + 1))
                ) {
                    strcpy(opts.c_val, optarg);
                } else {
                    exit(254);
                }

                opts.c = 1;
            } break;
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
