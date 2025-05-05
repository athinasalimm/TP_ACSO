#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "inode.h"
#include "diskimg.h"


/**
 * TODO
 */
int inode_iget(struct unixfilesystem *fs, int inumber, struct inode *inp) {
    if (inumber < 1) {
        fprintf(stderr, "Error: inumber < 1\n");
        return -1;
    }

    int sector = INODE_START_SECTOR + (inumber - 1) / 16;
    unsigned char buffer[DISKIMG_SECTOR_SIZE];

    if (diskimg_readsector(fs->dfd, sector, buffer) < 0) {
        fprintf(stderr, "Error: couldn't read sector %d\n", sector);
        return -1;
    }

    int index = (inumber - 1) % 16;
    struct inode *inodes = (struct inode*) buffer;
    *inp = inodes[index];  // copiamos el inodo leído a la salida

    return 0;
}

/**
 * TODO
 */
int inode_indexlookup(struct unixfilesystem *fs, struct inode *inp,
    int blockNum) {  
        //Implement code here
    return 0;
}

int inode_getsize(struct inode *inp) {
  return ((inp->i_size0 << 16) | inp->i_size1); 
}
