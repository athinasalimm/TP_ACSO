#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main(int argc, char **argv) {	
	int start, status, pid, n;
	int buffer[1];
	if (argc != 4){ printf("Uso el anillo <n> <c> <s> \n"); exit(0);}
  	n = atoi(argv[1]);    
    buffer[0] = atoi(argv[2]); 
    start = atoi(argv[3]); 
    printf("Se van a crear %i procesos, se va a enviar al caracter %i desde el proceso %i \n", n, buffer[0], start);
    int pipes[2 * n];
    for (int i = 0; i < n; i++) pipe(pipes + i * 2); 
    for (int i = 0; i < n; i++) {
        if (fork() == 0) {
            if (i == 0) {  
                buffer[0] += 1;
                write(pipes[i * 2 + 1], buffer, sizeof(int));
            } else {  
                read(pipes[(i - 1) * 2], buffer, sizeof(int));
                buffer[0] += 1;
                write(pipes[i * 2 + 1], buffer, sizeof(int));
            }
            close(pipes[i * 2]);
            close(pipes[i * 2 + 1]);
            exit(0);
        }
    }
    if (start == 0) write(pipes[1], buffer, sizeof(int));  
    read(pipes[(n - 1) * 2], buffer, sizeof(int));  
    for (int i = 0; i < n; i++) wait(NULL);  
    printf("Resultado final: %i\n", buffer[0]);
    return 0;
}