#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h> 

#define MAX_COMMANDS 200 //máximo numero de comandos que pueden haber en una línea (separados por las pipes)
#define MAX_ARGS 64 //este es el max num de argumentos que puede tener un comando 

char *trim(char *str) {
    while (*str == ' ' || *str == '\t') str++;
    char *end = str + strlen(str) - 1;
    while (end > str && (*end == ' ' || *end == '\t')) *end-- = '\0';
    return str;
} //con esta función elimino los espacios o los tabs al principio y al final de un string

int split_commands_respecting_quotes(char *line, char **commands) {
    int count = 0;
    char *start = line;
    int in_single_quote = 0, in_double_quote = 0;
    for (char *p = line; *p; p++) {
        if (*p == '\'' && !in_double_quote) {
            in_single_quote = !in_single_quote;
        } else if (*p == '"' && !in_single_quote) {
            in_double_quote = !in_double_quote;
        } else if (*p == '|' && !in_single_quote && !in_double_quote) {
            *p = '\0';
            commands[count++] = trim(start);
            start = p + 1;
            if (count >= MAX_COMMANDS) break;
        }
    }
    commands[count++] = trim(start); 
    return count;
} //divide una linea que tenga pipes en multiples comandos pero no parte si | esta en comillas. si si parte lo agce con \0 y guarda el comando

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
} //acá se verifica si no hay errores de uso incorrecto de pipes como: comando |, com || com, | com. 

int parse_args(char *cmd, char **args) {
    int argc = 0; //para contar cuantos argumentos voy guardando
    char *p = cmd;
    while (*p) { //hasta no llegar al final del string (cmd) itero
        while (isspace(*p)) p++; //para saltar los espacios iniciales
        if (*p == '\0') break;

        if (argc >= MAX_ARGS) {
            fprintf(stderr, "Demasiados argumentos\n");
            return -1;
        }
        if (*p == '"' || *p == '\'') { //para que si el argumento empieza con comillas se lea entero como 1
            char quote = *p++; //guardo el tipo de comillas que se usan
            char *start = p; //apunto al primer caracter post comillas, para poder marcar el inicio del argumento limpio q guardo en args[argc++] para pasar a execvp
            char *out = p; //apunto también a p, para poder reescribir el argumento limpio. 

            while (*p) { //itero para ir limpiando
                if (*p == '\\' && *(p + 1)) {
                    *out++ = *p++;
                    *out++ = *p++;
                } else if (*p == quote) {
                    break;
                } else {
                    *out++ = *p++;
                }
            }
            if (*p != quote) {
                fprintf(stderr, "Error: comillas sin cerrar\n");
                return -1;
            }
            *out = '\0'; 
            args[argc++] = start; //acá guardo el puntero al inicio del argumento ya limpio
            p++; 
        } else { //caso sin comillas
            args[argc++] = p;
            while (*p && !isspace(*p)) p++;
            if (*p) *p++ = '\0';
        }
    }
    args[argc] = NULL; //finalizo el array de argumentos con NULL para que execvp sepa cuando parar
    return 0;
}

int main() {
    char command[1024];
    char *commands[MAX_COMMANDS];
    int command_count = 0;
    while (1) {
        // if (isatty(STDIN_FILENO)) printf("Shell> ");
        printf("Shell> ");
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
        command_count = split_commands_respecting_quotes(command, commands);
        int pipes[2 * (command_count - 1)]; //creo los pipes necesarios 
        for (int i = 0; i < command_count - 1; i++) {
            if (pipe(pipes + i * 2) == -1) {
                perror("pipe");
                exit(1);
            }
        }
        for (int i = 0; i < command_count; i++) { //procesos hijos
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
                execvp(args[0], args); //ejecuto el comando 
                perror("execvp failed");
                exit(1);
            }
        }
        for (int i = 0; i < 2 * (command_count - 1); i++) close(pipes[i]); //cierro los extremos de los pipes en el padre
        for (int i = 0; i < command_count; i++) wait(NULL); //espero que terminen todos los hijos
    }
    return 0;
}