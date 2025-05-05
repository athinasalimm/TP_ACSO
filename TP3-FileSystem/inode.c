#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include "inode.h"
#include "diskimg.h"
#include <stdint.h>
#include "unixfilesystem.h"


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
    *inp = inodes[index];  

    return 0;
}

/**
 * TODO
 */
 int inode_indexlookup(struct unixfilesystem *fs, struct inode *inp, int fileBlockNum) {
     if (fileBlockNum < 0) {
         fprintf(stderr, "Error: fileBlockNum negativo\n");
         return -1;
     }
 
     // CASO 1: Archivo chico (todos los bloques son directos)
     if ((inp->i_mode & ILARG) == 0) {
         if (fileBlockNum >= 13) {
             fprintf(stderr, "Error: fileBlockNum fuera de rango (archivo chico)\n");
             return -1;
         }
         return inp->i_addr[fileBlockNum];
     }
 
     // CASO 2: Archivo grande (con bloques indirectos y doble indirecto)
 
     // Subcaso A: bloque indirecto (primeros 7 * 256 bloques)
     if (fileBlockNum < 7 * 256) {
         int indirectBlockIndex = fileBlockNum / 256;
         int offset = fileBlockNum % 256;
 
         unsigned char buffer[DISKIMG_SECTOR_SIZE];
 
         int indirBlockNum = inp->i_addr[indirectBlockIndex];
         if (diskimg_readsector(fs->dfd, indirBlockNum, buffer) < 0) {
             fprintf(stderr, "Error al leer bloque indirecto %d\n", indirBlockNum);
             return -1;
         }
 
         uint16_t *blockPointers = (uint16_t *)buffer;
         return blockPointers[offset];
     }
 
     // Subcaso B: bloque doblemente indirecto
     int remaining = fileBlockNum - 7 * 256;
     if (remaining >= 256 * 256) {
         fprintf(stderr, "Error: fileBlockNum fuera de rango (doble indirecto)\n");
         return -1;
     }
 
     int firstIndex = remaining / 256;
     int secondIndex = remaining % 256;
 
     unsigned char buffer1[DISKIMG_SECTOR_SIZE];
     unsigned char buffer2[DISKIMG_SECTOR_SIZE];
 
     int doubleIndirBlock = inp->i_addr[7];
 
     if (diskimg_readsector(fs->dfd, doubleIndirBlock, buffer1) < 0) {
         fprintf(stderr, "Error al leer bloque doble indirecto %d\n", doubleIndirBlock);
         return -1;
     }
 
     uint16_t *firstLevel = (uint16_t *)buffer1;
     int indirBlock = firstLevel[firstIndex];
 
     if (diskimg_readsector(fs->dfd, indirBlock, buffer2) < 0) {
         fprintf(stderr, "Error al leer segundo nivel %d\n", indirBlock);
         return -1;
     }
 
     uint16_t *secondLevel = (uint16_t *)buffer2;
     return secondLevel[secondIndex];
 }


int inode_getsize(struct inode *inp) {
  return ((inp->i_size0 << 16) | inp->i_size1); 
}
