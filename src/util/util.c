// SPDX-License-Identifier: GPL-2.0

// Parts are copied from the linux kernel

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

// CODE FROM LINUX KERNEL START

#define _U  0x01                /* upper */
#define _L  0x02                /* lower */
#define _D  0x04                /* digit */
#define _C  0x08                /* cntrl */
#define _P  0x10                /* punct */
#define _S  0x20                /* white space (space/lf/tab) */
#define _X  0x40                /* hex digit */
#define _SP 0x80                /* hard space (0x20) */

const unsigned char _ctype[] = {
        _C, _C, _C, _C, _C, _C, _C, _C, /* 0-7 */
        _C, _C | _S, _C | _S, _C | _S, _C | _S, _C | _S, _C, _C,        /* 8-15 */
        _C, _C, _C, _C, _C, _C, _C, _C, /* 16-23 */
        _C, _C, _C, _C, _C, _C, _C, _C, /* 24-31 */
        _S | _SP, _P, _P, _P, _P, _P, _P, _P,   /* 32-39 */
        _P, _P, _P, _P, _P, _P, _P, _P, /* 40-47 */
        _D, _D, _D, _D, _D, _D, _D, _D, /* 48-55 */
        _D, _D, _P, _P, _P, _P, _P, _P, /* 56-63 */
        _P, _U | _X, _U | _X, _U | _X, _U | _X, _U | _X, _U | _X, _U,   /* 64-71 */
        _U, _U, _U, _U, _U, _U, _U, _U, /* 72-79 */
        _U, _U, _U, _U, _U, _U, _U, _U, /* 80-87 */
        _U, _U, _U, _P, _P, _P, _P, _P, /* 88-95 */
        _P, _L | _X, _L | _X, _L | _X, _L | _X, _L | _X, _L | _X, _L,   /* 96-103 */
        _L, _L, _L, _L, _L, _L, _L, _L, /* 104-111 */
        _L, _L, _L, _L, _L, _L, _L, _L, /* 112-119 */
        _L, _L, _L, _P, _P, _P, _P, _C, /* 120-127 */
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 128-143 */
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 144-159 */
        _S | _SP, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P,   /* 160-175 */
        _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, _P, /* 176-191 */
        _U, _U, _U, _U, _U, _U, _U, _U, _U, _U, _U, _U, _U, _U, _U, _U, /* 192-207 */
        _U, _U, _U, _U, _U, _U, _U, _P, _U, _U, _U, _U, _U, _U, _U, _L, /* 208-223 */
        _L, _L, _L, _L, _L, _L, _L, _L, _L, _L, _L, _L, _L, _L, _L, _L, /* 224-239 */
        _L, _L, _L, _L, _L, _L, _L, _P, _L, _L, _L, _L, _L, _L, _L, _L  /* 240-255 */
};

#define __ismask(x) (_ctype[(int)(unsigned char)(x)])

#define kernel_isspace(c)  ((__ismask(c)&(_S)) != 0)

static char *skip_spaces(const char *str)
{
        while (kernel_isspace(*str))
                ++str;
        return (char *)str;
}

/*
 * Parse a string to get a param value pair.
 * You can use " around spaces, but can't escape ".
 * Hyphens and underscores equivalent in parameter names.
 */
static char *next_arg(char *args, char **param, char **val)
{
        unsigned int i, equals = 0;
        int in_quote = 0, quoted = 0;
        char *next;

        if (*args == '"') {
                args++;
                in_quote = 1;
                quoted = 1;
        }

        for (i = 0; args[i]; i++) {
                if (kernel_isspace(args[i]) && !in_quote)
                        break;
                if (equals == 0) {
                        if (args[i] == '=')
                                equals = i;
                }
                if (args[i] == '"')
                        in_quote = !in_quote;
        }

        *param = args;
        if (!equals)
                *val = NULL;
        else {
                args[equals] = '\0';
                *val = args + equals + 1;

                /* Don't include quotes in value. */
                if (**val == '"') {
                        (*val)++;
                        if (args[i - 1] == '"')
                                args[i - 1] = '\0';
                }
        }
        if (quoted && args[i - 1] == '"')
                args[i - 1] = '\0';

        if (args[i]) {
                args[i] = '\0';
                next = args + i + 1;
        } else
                next = args + i;

        /* Chew up trailing spaces. */
        return skip_spaces(next);
}

// CODE FROM LINUX KERNEL STOP

enum EXEC_MODE {
        UNDEFINED,
        GETARG,
        GETARGS,
};

static void usage(enum EXEC_MODE enumExecMode, int ret, char *msg)
{
        switch (enumExecMode) {
        case UNDEFINED:
                fprintf(stderr, "ERROR: 'dracut-util' has to be called via a symlink to the tool name.\n");
                break;
        case GETARG:
                fprintf(stderr, "ERROR: %s\nUsage: dracut-getarg <KEY>[=[<VALUE>]]\n", msg);
                break;
        case GETARGS:
                fprintf(stderr, "ERROR: %s\nUsage: dracut-getargs <KEY>[=]\n", msg);
                break;
        }
        exit(ret);
}

#define ARGV0_GETARG "dracut-getarg"
#define ARGV0_GETARGS "dracut-getargs"

static enum EXEC_MODE get_mode(const char *argv_0)
{
        struct _mode_table {
                enum EXEC_MODE mode;
                const char *arg;
                size_t arg_len;
                const char *s_arg;
        } modeTable[] = {
                {GETARG, ARGV0_GETARG, sizeof(ARGV0_GETARG), "/" ARGV0_GETARG},
                {GETARGS, ARGV0_GETARGS, sizeof(ARGV0_GETARGS), "/" ARGV0_GETARGS},
                {UNDEFINED, NULL, 0, NULL}
        };
        int i;

        size_t argv_0_len = strlen(argv_0);

        if (!argv_0_len)
                return UNDEFINED;

        for (i = 0; modeTable[i].mode != UNDEFINED; i++) {
                if (argv_0_len == (modeTable[i].arg_len - 1)) {
                        if (strncmp(argv_0, modeTable[i].arg, argv_0_len) == 0) {
                                return modeTable[i].mode;
                        }
                }

                if (modeTable[i].arg_len > argv_0_len)
                        continue;

                if (strncmp(argv_0 + argv_0_len - modeTable[i].arg_len, modeTable[i].s_arg, modeTable[i].arg_len) == 0)
                        return modeTable[i].mode;
        }
        return UNDEFINED;
}

static int getarg(int argc, char **argv)
{
        char *search_key;
        char *search_value;
        char *end_value = NULL;
        bool bool_value = false;
        char *cmdline = NULL;

        char *p = getenv("CMDLINE");
        if (p == NULL) {
                usage(GETARG, EXIT_FAILURE, "CMDLINE env not set");
        }
        cmdline = strdup(p);

        if (argc != 2) {
                usage(GETARG, EXIT_FAILURE, "Number of arguments invalid");
        }

        search_key = argv[1];

        search_value = strchr(argv[1], '=');
        if (search_value != NULL) {
                *search_value = 0;
                search_value++;
                if (*search_value == 0)
                        search_value = NULL;
        }

        if (strlen(search_key) == 0)
                usage(GETARG, EXIT_FAILURE, "search key undefined");

        do {
                char *key = NULL, *value = NULL;
                cmdline = next_arg(cmdline, &key, &value);
                if (strcmp(key, search_key) == 0) {
                        if (value) {
                                end_value = value;
                                bool_value = -1;
                        } else {
                                end_value = NULL;
                                bool_value = true;
                        }
                }
        } while (cmdline[0]);

        if (search_value) {
                if (end_value && strcmp(end_value, search_value) == 0) {
                        return EXIT_SUCCESS;
                }
                return EXIT_FAILURE;
        }

        if (end_value) {
                // includes "=0"
                puts(end_value);
                return EXIT_SUCCESS;
        }

        if (bool_value) {
                return EXIT_SUCCESS;
        }

        return EXIT_FAILURE;
}

static int getargs(int argc, char **argv)
{
        char *search_key;
        char *search_value;
        bool found_value = false;
        char *cmdline = NULL;

        char *p = getenv("CMDLINE");
        if (p == NULL) {
                usage(GETARGS, EXIT_FAILURE, "CMDLINE env not set");
        }
        cmdline = strdup(p);

        if (argc != 2) {
                usage(GETARGS, EXIT_FAILURE, "Number of arguments invalid");
        }

        search_key = argv[1];

        search_value = strchr(argv[1], '=');
        if (search_value != NULL) {
                *search_value = 0;
                search_value++;
                if (*search_value == 0)
                        search_value = NULL;
        }

        if (strlen(search_key) == 0)
                usage(GETARGS, EXIT_FAILURE, "search key undefined");

        do {
                char *key = NULL, *value = NULL;
                cmdline = next_arg(cmdline, &key, &value);
                if (strcmp(key, search_key) == 0) {
                        if (search_value) {
                                if (value && strcmp(value, search_value) == 0) {
                                        printf("%s\n", value);
                                        found_value = true;
                                }
                        } else {
                                if (value) {
                                        printf("%s\n", value);
                                } else {
                                        puts(key);
                                }
                                found_value = true;
                        }
                }
        } while (cmdline[0]);
        return found_value ? EXIT_SUCCESS : EXIT_FAILURE;
}

int main(int argc, char **argv)
{
        switch (get_mode(argv[0])) {
        case UNDEFINED:
                usage(UNDEFINED, EXIT_FAILURE, NULL);
                break;
        case GETARG:
                return getarg(argc, argv);
        case GETARGS:
                return getargs(argc, argv);
        }

        return EXIT_FAILURE;
}
