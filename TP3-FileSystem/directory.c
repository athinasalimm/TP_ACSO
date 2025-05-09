#include "directory.h"
#include "inode.h"
#include "diskimg.h"
#include "file.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

/**
 * TODO
 */
int directory_findname(struct unixfilesystem *fs, const char *name,
  int dirinumber, struct direntv6 *dirEnt) {
  struct inode dirinode;
  if (inode_iget(fs, dirinumber, &dirinode) < 0)
      return -1;
  if ((dirinode.i_mode & IALLOC) == 0 || ((dirinode.i_mode & IFMT) != IFDIR)) {
      fprintf(stderr, "directory_findname: inodo %d no es un directorio\n", dirinumber);
      return -1;
  }
  int filesize = inode_getsize(&dirinode);
  int blockCount = (filesize + DISKIMG_SECTOR_SIZE - 1) / DISKIMG_SECTOR_SIZE;
  for (int i = 0; i < blockCount; i++) {
      unsigned char buffer[DISKIMG_SECTOR_SIZE];
      int bytes = file_getblock(fs, dirinumber, i, buffer);
      if (bytes < 0) return -1;
      int entries = bytes / sizeof(struct direntv6);
      struct direntv6 *entry = (struct direntv6 *)buffer;
      for (int j = 0; j < entries; j++) {
          if (strncmp(entry[j].d_name, name, DIR_NAME_SIZE) == 0) {
              *dirEnt = entry[j];  
              return 0;
          }
      }
  }
  return -1;  
}