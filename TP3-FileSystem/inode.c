#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "inode.h"
#include "diskimg.h"

/**
 * TODO
 */
int inode_iget(struct unixfilesystem *fs, int inumber, struct inode *inp) {
    if (inumber < 1) return -1;

    int inodesPerSector = DISKIMG_SECTOR_SIZE / sizeof(struct inode);
    int sector = INODE_START_SECTOR + (inumber - 1) / inodesPerSector;

    unsigned char buffer[DISKIMG_SECTOR_SIZE];
    if (diskimg_readsector(fs->dfd, sector, buffer) < 0)
        return -1;

    int index = (inumber - 1) % inodesPerSector;
    struct inode *inodes = (struct inode *)buffer;
    *inp = inodes[index];

    return 0;
}

/**
 * TODO
 */
int inode_indexlookup(struct unixfilesystem *fs, struct inode *inp, int fileBlockNum) {
    if (fileBlockNum < 0) return -1;

    // CASO 1: archivo chico (13 bloques directos)
    if ((inp->i_mode & ILARG) == 0) {
        if (fileBlockNum >= 13) return -1;
        return inp->i_addr[fileBlockNum];
    }

    // CASO 2: archivo grande (bloques indirectos)
    if (fileBlockNum < 7 * 256) {
        int indirIndex = fileBlockNum / 256;
        int offset = fileBlockNum % 256;

        if (inp->i_addr[indirIndex] == 0) return -1;  // 🛡️ Chequeo: bloque indirecto no asignado

        int indirBlock = inp->i_addr[indirIndex];

        unsigned char buffer[DISKIMG_SECTOR_SIZE];
        if (diskimg_readsector(fs->dfd, indirBlock, buffer) < 0)
            return -1;

        uint16_t *table = (uint16_t *)buffer;
        return table[offset];
    }

    // CASO 3: archivo muy grande (doble indirecto)
    int remaining = fileBlockNum - 7 * 256;
    if (remaining >= 256 * 256) return -1;

    int first = remaining / 256;
    int second = remaining % 256;

    unsigned char buffer1[DISKIMG_SECTOR_SIZE];
    unsigned char buffer2[DISKIMG_SECTOR_SIZE];

    if (inp->i_addr[7] == 0) return -1;  // 🛡️ Chequeo: bloque doble indirecto no asignado

    if (diskimg_readsector(fs->dfd, inp->i_addr[7], buffer1) < 0)
        return -1;

    uint16_t *level1 = (uint16_t *)buffer1;

    if (level1[first] == 0) return -1;  // 🛡️ Chequeo: puntero de primer nivel no asignado

    if (diskimg_readsector(fs->dfd, level1[first], buffer2) < 0)
        return -1;

    uint16_t *level2 = (uint16_t *)buffer2;
    return level2[second];
}

int inode_getsize(struct inode *inp) {
    return ((inp->i_size0 << 16) | inp->i_size1); 
  }