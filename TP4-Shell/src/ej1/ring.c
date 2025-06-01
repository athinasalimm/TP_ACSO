#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

//dejé en comentarios los prints que me fueron ayudando a entender mejor el anillo y donde estaba haciendo cosas mal 

int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "Uso: ./anillo <n> <c> <s>\n");
        exit(1);
    }
    int n = atoi(argv[1]);      
    int value = atoi(argv[2]);  
    int start = atoi(argv[3]);  
    if (n < 3 || start < 0 || start >= n) {
        fprintf(stderr, "Error: n >= 3 y 0 <= s < n\n");
        exit(1);
    }
    int pipes[n][2];      
    int retorno[2];      
    pipe(retorno);
    for (int i = 0; i < n; i++) {
        if (pipe(pipes[i]) == -1) {
            perror("pipe");
            exit(1);
        }
    }
    for (int i = 0; i < n; i++) {
        pid_t pid = fork();
        if (pid < 0) {
            perror("fork");
            exit(1);
        }
        if (pid == 0) {
            for (int j = 0; j < n; j++) {
                if (j != (i - 1 + n) % n) close(pipes[j][0]); 
                if (j != i) close(pipes[j][1]);              
            }
            if (i == start) {
                close(retorno[0]); 
                int num;
                //printf("Hijo %d (start) esperando mensaje final del anillo...\n", i);
                read(pipes[(i - 1 + n) % n][0], &num, sizeof(int));
                num++;
                //printf("Hijo %d (start) recibió, incrementa y lo manda al PADRE: %d\n", i, num);
                write(retorno[1], &num, sizeof(int));
                close(retorno[1]);
                close(pipes[(i - 1 + n) % n][0]);
                exit(0);
            } else {
                close(retorno[0]);
                close(retorno[1]);
                int num;
                // printf("Hijo %d esperando mensaje de Hijo %d...\n", i, (i - 1 + n) % n);
                read(pipes[(i - 1 + n) % n][0], &num, sizeof(int));
                // printf("Hijo %d recibió %d, incrementa y envía a Hijo %d\n", i, num, (i + 1) % n);
                num++;
                write(pipes[i][1], &num, sizeof(int));
                close(pipes[(i - 1 + n) % n][0]);
                close(pipes[i][1]);
                exit(0);
            }
        }
    }
    for (int i = 0; i < n; i++) {
        close(pipes[i][0]);
        if (i != start) close(pipes[i][1]); 
    }
    close(retorno[1]);
    // printf("Padre envía %d al proceso %d\n", value, start);
    write(pipes[start][1], &value, sizeof(int));
    close(pipes[start][1]);
    int final;
    read(retorno[0], &final, sizeof(int));
    close(retorno[0]);
    for (int i = 0; i < n; i++) wait(NULL);
    printf("Resultado final: %d\n", final);
    return 0;
}
