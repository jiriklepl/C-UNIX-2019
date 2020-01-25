#include "shell-common.h"
#include "shell.tab.h"

struct prgv_t {
    /*
        * output and input, NULL represents there is no redirection
        * (pipe is still considered NULL)
        */
    char *_out, *_in;

    // true if >>, false if >, nondeterministic otherwise
    bool _append;
};

extern FILE *yyin;

YYSTYPE yylval;

struct string_queue queue_head;
size_t lineno = 1;

static struct sigaction int_action, chld_action;

static int last_return_value;
static int redisplay = 1;
static int is_interactive = 1;

static char *cwd;
static char *input_line = NULL;

void use_prefix(void);
void switch_store_cwd(void);
void end_lexical_scan(void);

void set_input_string(const char *);

void intHandler(int sig);
void chldHandler(int sig);

int parse_line(void);
int parse_loop(void);

int parse_string_loop(char *from_string);
int parse_file_loop(char *fname);

void open_child(
    char *argv[],
    struct prgv_t *prgv);

void run_cd(char *argv[]);


void run_pipeline(void) {
    queue_union *entry;

    /*
     * argv points to compact array of program arguments
     * each terminated with a NULL entry
     * argv[0] is also NULL
     */
    char **argv;

    /*
     * array of structs describing redirections (raw)
     */
    struct prgv_t *prgv;

    size_t argc = 0;
    size_t prgc = 1;

    // this determines how many arguments and programs are in the pipeline
    STAILQ_FOREACH(entry, &queue_head, _next) {
        switch (entry->_type) {
            case QU_STRING:
                ++argc;
            break;

            case QU_PIPE:
                ++prgc;
            break;

            case QU_RARROW:
            case QU_DRARROW:
            case QU_LARROW:
                // these just modify in/out
            case QU_EMPTY:
            break;
        }
    }

    if (
        (argv = malloc(sizeof(char *) * (argc + prgc + 1))) == NULL ||
        (prgv = malloc(sizeof(struct prgv_t) * prgc)) == NULL
    ) {
        exit(GENERAL_ERROR);
    }

    for (size_t i = 0; i < prgc; ++i) {
        prgv[i]._out = prgv[i]._in = NULL;
    }

    argc = 1;
    prgc = 0;

    argv[0] = NULL;

    /*
     * this fills both argv and prgv arrays
     * and epties the queue
     */
    while (!STAILQ_EMPTY(&queue_head)) {
        queue_union *entry = STAILQ_FIRST(&queue_head);
        STAILQ_REMOVE_HEAD(&queue_head, _next);

        switch (entry->_type) {
            case QU_STRING:
                argv[argc + prgc] = entry->_val._str;
                ++argc;
            break;

            case QU_RARROW:
                free(prgv[prgc]._out);
                prgv[prgc]._out = entry->_val._str;
                prgv[prgc]._append = false;
            break;

            case QU_DRARROW:
                free(prgv[prgc]._out);
                prgv[prgc]._out = entry->_val._str;
                prgv[prgc]._append = true;
            break;

            case QU_LARROW:
                free(prgv[prgc]._in);
                prgv[prgc]._in = entry->_val._str;
            break;

            case QU_PIPE:
                argv[argc + prgc] = NULL;
                ++prgc;
            break;

            case QU_EMPTY:
            break;
        }

        free(entry);
    }

    argv[argc + prgc] = NULL;

    int pd[3] = {0, 1, -1};

    size_t actual_argc = argc;
    size_t actual_prgc = prgc + 1;

    --argc;

    pid_t cpid;

    while (prgc != 0) {
        /*
         * find the first null on the argv array below argc + prgc
         * and set argc accordingly so argc + prgc points to that
         */
        while (argv[argc + prgc] != NULL) {
            --argc;
        }

        if (pipe(pd) == -1) {
            perror("pipe");
            exit(GENERAL_ERROR);
        }

        switch (cpid = fork()) {
            case -1:
                perror("fork");
                exit(GENERAL_ERROR);
            break;

            case 0:
                if (
                    ((pd[2] != -1) && (
                        dup2(pd[2], STDOUT_FILENO) == -1 ||
                        close(pd[2]) == -1)) ||
                    dup2(pd[0], STDIN_FILENO) == -1 ||
                    close(pd[0]) == -1 ||
                    close(pd[1]) == -1
                ) {
                    perror("pipe");
                    exit(GENERAL_ERROR);
                } else {
                    open_child(argv + argc + prgc + 1, prgv + prgc);

                    // we get here iff first argument here is either cd or exit
                    exit(last_return_value);
                }
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

    // the first command has at least one argument (or parse error)
    assert(*(argv + 1) != NULL);

    if (
        strcmp(*(argv + 1), "cd") != 0 &&
        strcmp(*(argv + 1), "exit") != 0
    ) {
        cpid = fork();
    } else {
        if (pd[2] != -1) {
            close(pd[2]);
            pd[2] = -1;
        }

        cpid = 0;
    }

    switch (cpid) {
        case -1:
            perror("fork");
            exit(GENERAL_ERROR);
        break;

        case 0:
            if (pd[2] != -1) {
                if (
                    dup2(pd[2], STDOUT_FILENO) == -1 ||
                    close(pd[2]) == -1
                ) {
                    perror("pipe");
                    exit(GENERAL_ERROR);
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

void run_cd(char *argv[]) {
    if (argv[1] == NULL) {
        // cd home
        if ((last_return_value = chdir(getenv("HOME"))) == 0) {
            switch_store_cwd();
        } else {
            use_prefix();
            fprintf(stderr, "Cannot go to $HOME: %s\n", getenv("HOME"));
        }
    } else if (argv[2] != NULL) {
        // too many arguments
        use_prefix();
        fprintf(stderr, "cd: too many arguments\n");
        last_return_value = 1;
    } else if (strcmp(argv[1], "-") == 0) {
        // cd to OLDPWD (swap with PWD)
        if ((last_return_value = chdir(getenv("OLDPWD"))) == 0) {
            switch_store_cwd();
            printf("%s\n", cwd);
        } else {
            use_prefix();
            fprintf(stderr, "Cannot go to $OLDPWD: %s\n", getenv("OLDPWD"));
        }
    } else {
        if ((last_return_value = chdir(argv[1])) == 0) {
            switch_store_cwd();
        } else {
            use_prefix();
            fprintf(stderr, "Cannot go to %s\n", argv[1]);
        }
    }
}

// argv points to the first argument, prgv to the configuration struct
void open_child(
    char *argv[],
    struct prgv_t *prgv
) {
    assert(argv != NULL);
    assert(*argv != NULL);

    if (strcmp(*argv, "cd") == 0) {
        run_cd(argv);
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

            if (prgv->_append) {
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

    while ((w = wait(&wstatus)) != -1) {
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

        if (
            len < 0 ||
            (prompt = malloc(len + 1)) == NULL
        ) {
            exit(GENERAL_ERROR);
        } else {
            snprintf(prompt, len + 1, MYSH_PROMPT, cwd);
        }

        input_line = readline(prompt);

        free(prompt);

        if (input_line == NULL) {
            clear_queue();
            printf("exit\n");

            break;
        }

        if (
            strlen(input_line) > 0 &&
            input_line[0] != ' '
        ) {
            add_history(input_line);
        }

        if (parse_line()) {
            last_return_value = GENERAL_ERROR;
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
            last_return_value = GENERAL_ERROR;
        }

        free(input_line);
    }

    clear_queue();

    return last_return_value;
}

int parse_file_loop(char *fname) {
    FILE *fh = fopen(fname, "r");

    if (fh == NULL) {
        errx(GENERAL_ERROR, "Cannot open the file %s\n", fname);
    }

    yyin = fh;

    if (yyparse()) {
        last_return_value = GENERAL_ERROR;
    }

    fclose(fh);
    clear_queue();

    return last_return_value;
}

int main(int argc, char *argv[]) {
    struct {
        int c;
        char *c_val;
    } opts = { .c = 0, .c_val = NULL };

    int opt;

    while ((opt = getopt(argc, argv, "c:")) != -1) {
        switch (opt) {
            case 'c': {
                size_t len;

                if (opts.c_val != NULL) {
                    free(opts.c_val);
                    opts.c_val = NULL;
                }

                if (
                    (len = strlen(optarg)) > 0 &&
                    (opts.c_val = malloc(len + 1))
                ) {
                    strcpy(opts.c_val, optarg);
                } else {
                    exit(GENERAL_ERROR);
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

    switch_store_cwd();

    if (opts.c == 1) {
        return parse_string_loop(opts.c_val);
    } else if (argc == 1) {
        return parse_loop();
    } else {
        is_interactive = 0;
        return parse_file_loop(argv[optind]);
    }
}

void use_prefix(void) {
    if (!is_interactive) {
        fprintf(stderr, "Line %zu: ", lineno);
    }
}

void switch_store_cwd(void) {
    char *new_cwd = NULL;

    if (((cwd == NULL)
            ? unsetenv("OLDPWD")
            : setenv("OLDPWD", cwd, 1)) == -1 ||
        (new_cwd = getcwd(NULL, 0)) == NULL ||
        setenv("PWD", new_cwd, 1) == -1
    ) {
        exit(GENERAL_ERROR);
    }

    free(new_cwd);
    cwd = getenv("PWD");
}

int yyerror(const char *s) {
    use_prefix();
    fprintf(stderr, "%s\n", s);

    return 127;
}
