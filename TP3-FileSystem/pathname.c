
#include "pathname.h"
#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

/**
 * TODO
 */
int pathname_lookup(struct unixfilesystem *fs, const char *pathname) {
    if (pathname == NULL || pathname[0] != '/') return -1;

    char pathcopy[1024];  // hacemos copia porque strtok modifica el string
    strncpy(pathcopy, pathname, sizeof(pathcopy));
    pathcopy[sizeof(pathcopy) - 1] = '\0';  // por seguridad

    int inumber = 1;  // empezamos desde la raíz

    char *token = strtok(pathcopy, "/");
    while (token != NULL) {
        struct direntv6 dirEntry;
        if (directory_findname(fs, token, inumber, &dirEntry) < 0)
            return -1;

        inumber = dirEntry.d_inumber;
        token = strtok(NULL, "/");
    }

    return inumber;
}
