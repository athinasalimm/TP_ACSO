// #include <stdio.h>
// #include <stdlib.h>
// #include <unistd.h>
// #include <sys/wait.h>
// #include <string.h>
// #include <ctype.h>
// #include <wordexp.h>

// #define MAX_COMMANDS 205
// #define MAX_ARGS 64

// // Elimina espacios iniciales y finales
// char *trim(char *str) {
//     while (*str == ' ' || *str == '\t') str++;
//     char *end = str + strlen(str) - 1;
//     while (end > str && (*end == ' ' || *end == '\t')) *end-- = '\0';
//     return str;
// }

// // Verifica errores de sintaxis básicos
// int has_syntax_error(char *line) {
//     char *p = line;
//     int last_was_pipe = 1;  // al principio, es como si hubiera un pipe
//     while (*p) {
//         if (*p == '|') {
//             if (last_was_pipe) return 1; // pipe vacío o doble
//             last_was_pipe = 1;
//         } else if (!isspace(*p)) {
//             last_was_pipe = 0;
//         }
//         p++;
//     }
//     return last_was_pipe;  // termina en pipe → error
// }

// // Parsea argumentos respetando comillas dobles
// void parse_args(char *cmd, char **args) {
//     wordexp_t p;
//     if (wordexp(cmd, &p, 0) != 0) {
//         fprintf(stderr, "Error al parsear argumentos\n");
//         exit(1);
//     }

//     for (int i = 0; i < p.we_wordc && i < MAX_COMMANDS - 1; i++) {
//         args[i] = p.we_wordv[i];
//     }
//     args[p.we_wordc] = NULL;

//     if (p.we_wordc > MAX_COMMANDS - 1) {
//         fprintf(stderr, "Demasiados argumentos\n");
//         wordfree(&p);
//         exit(1);
//     }
// }

// int main() {
//     char command[1024];
//     char *commands[MAX_COMMANDS];
//     int command_count = 0;

//     while (1) {
//         if (isatty(STDIN_FILENO)) {
//             printf("Shell> ");
//         }

//         if (fgets(command, sizeof(command), stdin) == NULL) {
//             printf("\n");
//             break;
//         }

//         command[strcspn(command, "\n")] = '\0';
//         if (strcmp(command, "exit") == 0) break;

//         if (has_syntax_error(command)) {
//             fprintf(stderr, "Error de sintaxis\n");
//             continue;
//         }

//         // Separar por pipes
//         command_count = 0;
//         char *token = strtok(command, "|");
//         while (token != NULL && command_count < MAX_COMMANDS) {
//             commands[command_count++] = trim(token);
//             token = strtok(NULL, "|");
//         }

//         int pipes[2 * (command_count - 1)];
//         for (int i = 0; i < command_count - 1; i++) {
//             if (pipe(pipes + i * 2) == -1) {
//                 perror("pipe");
//                 exit(1);
//             }
//         }

//         for (int i = 0; i < command_count; i++) {
//             pid_t pid = fork();
//             if (pid < 0) {
//                 perror("fork");
//                 exit(1);
//             }

//             if (pid == 0) {
//                 if (i > 0) {
//                     dup2(pipes[(i - 1) * 2], STDIN_FILENO);
//                 }
//                 if (i < command_count - 1) {
//                     dup2(pipes[i * 2 + 1], STDOUT_FILENO);
//                 }
//                 for (int j = 0; j < 2 * (command_count - 1); j++) {
//                     close(pipes[j]);
//                 }

//                 char *args[MAX_ARGS + 1];
//                 parse_args(commands[i], args);

//                 if (args[0] == NULL) {
//                     fprintf(stderr, "Comando vacío\n");
//                     exit(1);
//                 }

//                 execvp(args[0], args);
//                 perror("execvp failed");
//                 exit(1);
//             }
//         }

//         for (int i = 0; i < 2 * (command_count - 1); i++) {
//             close(pipes[i]);
//         }

//         for (int i = 0; i < command_count; i++) {
//             wait(NULL);
//         }
//     }

//     return 0;
// }


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>
#include <ctype.h>
#include <wordexp.h>

#define MAX_COMMANDS 205
#define MAX_ARGS 64

// Elimina espacios iniciales y finales
char *trim(char *str) {
    while (*str == ' ' || *str == '\t') str++;
    char *end = str + strlen(str) - 1;
    while (end > str && (*end == ' ' || *end == '\t')) *end-- = '\0';
    return str;
}

// Verifica errores de sintaxis como pipes vacios, duplicados o al inicio/final
int has_syntax_error(char *line) {
    char *p = line;
    int last_was_pipe = 1;
    while (*p) {
        if (*p == '|') {
            if (last_was_pipe) return 1;
            last_was_pipe = 1;
        } else if (!isspace(*p)) {
            last_was_pipe = 0;
        }
        p++;
    }
    return last_was_pipe;
}

// Parsea argumentos usando wordexp (maneja comillas, tabs, espacios, etc.)
int parse_args(char *cmd, char **args) {
    wordexp_t p;
    if (wordexp(cmd, &p, 0) != 0) {
        fprintf(stderr, "Error al parsear argumentos\n");
        return -1;
    }
    if (p.we_wordc >= MAX_ARGS) {
        fprintf(stderr, "Demasiados argumentos\n");
        wordfree(&p);
        return -1;
    }
    for (int i = 0; i < p.we_wordc; i++) {
        args[i] = p.we_wordv[i];
    }
    args[p.we_wordc] = NULL;
    return 0;
}

int main() {
    char command[1024];
    char *commands[MAX_COMMANDS];
    int command_count = 0;

    while (1) {
        if (isatty(STDIN_FILENO)) printf("Shell> ");

        if (fgets(command, sizeof(command), stdin) == NULL) {
            printf("\n");
            break;
        }

        command[strcspn(command, "\n")] = '\0';
        if (strcmp(command, "exit") == 0) break;

        if (has_syntax_error(command)) {
            fprintf(stderr, "Error de sintaxis\n");
            continue;
        }

        command_count = 0;
        char *token = strtok(command, "|");
        while (token != NULL && command_count < MAX_COMMANDS) {
            commands[command_count++] = trim(token);
            token = strtok(NULL, "|");
        }

        int pipes[2 * (command_count - 1)];
        for (int i = 0; i < command_count - 1; i++) {
            if (pipe(pipes + i * 2) == -1) {
                perror("pipe");
                exit(1);
            }
        }

        for (int i = 0; i < command_count; i++) {
            pid_t pid = fork();
            if (pid < 0) {
                perror("fork");
                exit(1);
            }
            if (pid == 0) {
                if (i > 0) dup2(pipes[(i - 1) * 2], STDIN_FILENO);
                if (i < command_count - 1) dup2(pipes[i * 2 + 1], STDOUT_FILENO);
                for (int j = 0; j < 2 * (command_count - 1); j++) close(pipes[j]);

                char *args[MAX_ARGS + 1];
                if (parse_args(commands[i], args) != 0) exit(1);
                if (args[0] == NULL) {
                    fprintf(stderr, "Comando vac\u00edo\n");
                    exit(1);
                }

                execvp(args[0], args);
                perror("execvp failed");
                exit(1);
            }
        }

        for (int i = 0; i < 2 * (command_count - 1); i++) close(pipes[i]);
        for (int i = 0; i < command_count; i++) wait(NULL);
    }

    return 0;
}