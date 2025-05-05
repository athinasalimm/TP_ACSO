#ifndef _DIRENTV6_H_
#define _DIRENTV6_H_

#include <stdint.h>

/**
 * The Unix Version 6 code didn't use a structure like this but this is 
 * structure does match for format of a directory entry.
 */
#define DIR_NAME_SIZE 14

struct direntv6 {
  uint16_t d_inumber;   
  char     d_name[DIR_NAME_SIZE];
};

#endif // _DIRENTV6_H_
