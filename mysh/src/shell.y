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

%code requires
{
    #include "shell-common.h"
}

%code
{
    YYSTYPE yylval;
    size_t lineno = 1;
    char *input_line = NULL;
    int is_interactive = 1;

    extern FILE *yyin;

    int last_return_value;
    char cwd[PATH_MAX];
    char old_cwd[PATH_MAX];
    int redisplay = 1;

    void use_prefix();
    void switch_store_cwd();
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
    | request NLINE
    ;

command_bit:
    STRING {
        string *entry;

        if ((entry = malloc(sizeof (string)))) {
            if ((entry->_value = malloc(yylval._val._str._len + 1))) {
                memcpy(
                    entry->_value,
                    yylval._val._str._beg,
                    yylval._val._str._len);
                entry->_value[yylval._val._str._len] = '\0';
                STAILQ_INSERT_TAIL(&queue_head, entry, _next);
            } else {
                free(entry);
            }
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

        STAILQ_FOREACH(entry, &queue_head, _next)
            ++i;


        if ((argv = malloc(sizeof (char *) * (i + 1)))) {
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
                        switch_store_cwd();
                        printf("%s\n", cwd);
                    } else {
                        use_prefix();
                        fprintf(
                            stderr,
                            "Cannot go to $HOME: %s\n",
                            getenv("HOME"));
                    }
                } else if (strcmp(argv[1], "-") == 0) {
                    // cd to OLDPWD (swap with PWD)
                    if ((last_return_value = chdir(getenv("OLDPWD"))) == 0) {
                        switch_store_cwd();
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
                        switch_store_cwd();
                        printf("%s\n", cwd);
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
                pid_t cpid, w;
                int wstatus;
                int rv;

                cpid = fork();

                if (cpid == -1) {
                    perror("fork");
                    exit(EXIT_FAILURE);
                } else if (cpid == 0) {
                    // child

                    if ((rv = execvp(*argv, argv))) {
                        use_prefix();
                        fprintf(
                            stderr,
                            "%s - No such file or directory\n",
                            *argv);
                        exit(127);
                    }
                } else {
                    redisplay = 0;

                    // parent
                    do {
                        w = waitpid(cpid, &wstatus, WUNTRACED);
                        if (w == -1) {
                            perror("waitpid");
                            exit(EXIT_FAILURE);
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
                    } while (!WIFEXITED(wstatus) && !WIFSIGNALED(wstatus));
                }
            }

            while (i-- > 0) {
                free(argv[i]);
            }

            free(argv);

            redisplay = 1;
        }
    }
    | command_sequence PIPE command
    ;
%%

void set_input_string(const char *);
void end_lexical_scan(void);

/* This function parses a string */

int parse_line()
{
    set_input_string(input_line);
    int rv = yyparse();
    end_lexical_scan();

    return rv;
}

void intHandler(int sig)
{
    signal(sig, SIG_IGN);

    // bash does that
    last_return_value = 130;

    if (redisplay) {
        rl_point = 0;
        rl_delete_text(0, rl_end);
        rl_reset_line_state();
        printf("\n");
        rl_redisplay();
    }

    signal(SIGINT, intHandler);
}

int parse_loop()
{
    if (getcwd(cwd, sizeof (cwd)) == NULL) {
        exit(127);
    }

    while (1) {
        char *prompt = NULL;
        int len = snprintf(NULL, 0, MYSH_PROMPT, cwd);

        if ((prompt = malloc(len + 1))) {
            snprintf(prompt, len + 1, MYSH_PROMPT, cwd);
        }

        input_line = readline(prompt);

        free(prompt);

        if (input_line == NULL) {
            break;
        }

        if (strlen(input_line) > 0 && input_line[0] != ' ') {
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

int parse_string_loop(char *from_string)
{
    if (from_string == NULL) {
        // TODO:
        return 127;
    }

    input_line = from_string;

    if (parse_line()) {
        last_return_value = 254;
    }

    free(input_line);
    clear_queue();

    return last_return_value;
}

int parse_file_loop(char *fname)
{
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

int main(int argc, char *argv[])
{
    struct {
        int c;
        int c_len;
        char *c_val;
    } opts = { .c = 0 };

    int opt;

    while ((opt = getopt(argc, argv, "c:")) != -1) {
        switch (opt) {
            case 'c':
                opts.c = 1;

                if (
                    (opts.c_len = strlen(optarg)) > 0 &&
                    (opts.c_val = malloc(opts.c_len + 1))
                ) {
                    strcpy(opts.c_val, optarg);
                } else {
                    opts.c_val = NULL;
                    // TODO: error
                }
            break;
        }
    }

    signal(SIGINT, intHandler);
    STAILQ_INIT(&queue_head);
    if (opts.c == 1) {
        return parse_string_loop(opts.c_val);
    } else if (argc == 1) {
        return parse_loop();
    } else {
        is_interactive = 0;
        return parse_file_loop(argv[optind]);
    }
}

void use_prefix()
{
	if (!is_interactive) {
        fprintf(stderr, "Line %zu: ", lineno);
    }
}

void switch_store_cwd()
{
    for (size_t i = 0; i < PATH_MAX; ++i) {
        char t = cwd[i];
        cwd[i] = old_cwd[i];
        old_cwd[i] = t;
    }

    setenv("OLDPWD", old_cwd, 1);
    if (getcwd(cwd, sizeof (cwd)) == NULL) {
        char *env_cwd = getenv("PWD");
        if (env_cwd) {
            strcpy(cwd, env_cwd);
        } else {
            cwd[0] = '\0';
        }
    }
}

int yyerror(char *s)
{
    use_prefix();
	fprintf(stderr, "%s\n", s);

    return 127;
}
