#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>

#define MAX_COMMANDS 205

// Función para eliminar espacios iniciales y finales
char *trim(char *str) {
    while (*str == ' ') str++;  // Espacios al inicio
    char *end = str + strlen(str) - 1;
    while (end > str && *end == ' ') *end-- = '\0';  // Espacios al final
    return str;
}

// Función para separar un comando en sus argumentos
void parse_args(char *cmd, char **args) {
    int j = 0;
    args[j] = strtok(cmd, " ");
    while (args[j] != NULL) {
        // Eliminar comillas si están al inicio y final
        if (args[j][0] == '"' && args[j][strlen(args[j]) - 1] == '"') {
            args[j][strlen(args[j]) - 1] = '\0';  // Corto la comilla del final
            args[j]++;  // Avanzo uno para saltear la comilla del principio
        }

        j++;
        args[j] = strtok(NULL, " ");
    }
    args[j] = NULL;
}

int main() {
    char command[256];
    char *commands[MAX_COMMANDS];
    int command_count = 0;

    while (1) {
        if (isatty(STDIN_FILENO)) {
            printf("Shell> ");
        }
        
        // Leer línea de comando
        if (fgets(command, sizeof(command), stdin) == NULL) {
            printf("\n");  // Ctrl+D
            break;
        }

        // Eliminar salto de línea
        command[strcspn(command, "\n")] = '\0';

        // Salir con "exit"
        if (strcmp(command, "exit") == 0) {
            break;
        }

        // Separar por pipes
        char *token = strtok(command, "|");
        command_count = 0;
        while (token != NULL) {
            commands[command_count++] = trim(token);  // limpia espacios
            token = strtok(NULL, "|");
        }

        // Crear pipes
        int pipes[2 * (command_count - 1)];
        for (int i = 0; i < command_count - 1; i++) {
            if (pipe(pipes + i * 2) == -1) {
                perror("Pipe failed");
                exit(1);
            }
        }

        // Ejecutar comandos
        for (int i = 0; i < command_count; i++) {
            pid_t pid = fork();
            if (pid < 0) {
                perror("Fork failed");
                exit(1);
            }

            if (pid == 0) {
                // Redirigir entrada si no es el primer comando
                if (i > 0) {
                    if (dup2(pipes[(i - 1) * 2], STDIN_FILENO) == -1) {
                        perror("dup2 stdin failed");
                        exit(1);
                    }
                }

                // Redirigir salida si no es el último comando
                if (i < command_count - 1) {
                    if (dup2(pipes[i * 2 + 1], STDOUT_FILENO) == -1) {
                        perror("dup2 stdout failed");
                        exit(1);
                    }
                }

                // Cerrar todos los pipes
                for (int j = 0; j < 2 * (command_count - 1); j++) {
                    close(pipes[j]);
                }

                // Parsear el comando en args y ejecutar
                char *args[MAX_COMMANDS];
                parse_args(commands[i], args);

                execvp(args[0], args);
                perror("execvp failed");
                exit(1);
            }
        }

        // Cerrar todos los pipes en el padre
        for (int i = 0; i < 2 * (command_count - 1); i++) {
            close(pipes[i]);
        }

        // Esperar que terminen todos los hijos
        for (int i = 0; i < command_count; i++) {
            wait(NULL);
        }
    }

    return 0;
}