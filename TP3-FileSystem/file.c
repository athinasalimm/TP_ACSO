#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "file.h"
#include "inode.h"
#include "diskimg.h"

/**
 * TODO
 */
int file_getblock(struct unixfilesystem *fs, int inumber, int fileBlockNum, void *buf) {
    struct inode in;
    if (inode_iget(fs, inumber, &in) < 0)
        return -1;
    if ((in.i_mode & IALLOC) == 0)
    return -1; 
    int size = inode_getsize(&in);
    int totalBlocks = (size + DISKIMG_SECTOR_SIZE - 1) / DISKIMG_SECTOR_SIZE;
    if (fileBlockNum >= totalBlocks) return -1;
    int diskBlockNum = inode_indexlookup(fs, &in, fileBlockNum);
    if (diskBlockNum == -1) return -1;
    if (diskimg_readsector(fs->dfd, diskBlockNum, buf) < 0)
        return -1;
    int offset = fileBlockNum * DISKIMG_SECTOR_SIZE;
    int remaining = size - offset;
    return (remaining > DISKIMG_SECTOR_SIZE) ? DISKIMG_SECTOR_SIZE : remaining;
}