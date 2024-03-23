#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>

unsigned char memory [16384];

unsigned char romHeader [] = {0034, 0000, 0377, 0252, 0000, 0001, 0004, 0000,
                              0000, 0000, 0046, 0104, 0000, 0000, 0000, 0000,
                              0000, 0000, 0000, 0000, 0032, 0000, 0000, 0300,
                              0002, 0000};

int calcChecksum (unsigned char * buffer, int size) {
  int i, acc=0177777;
  for (i=0; i < (size>>1); i++) {
    int lowByte = *(buffer++);
    int highByte = *(buffer++);
    int carry;
    int data = ((highByte << 8) & 0xff00) | (lowByte & 0xff); 
    acc = acc ^ data;
    acc = acc << 1;
    carry = (acc >> 16) & 1;
    acc = acc + carry;
  }
  return acc;
}


int main (int argc, char *argv[]) 
{
  FILE * in;
  struct stat s;
  int i;
  int acc = 0xffff;
  unsigned short id = 0000034;
  int memorySize = 4;
  int fileSize;
  int checksum;

  if (argc != 2) {
    fprintf(stderr, "Wrong number of arguments. Program need one parameter. Filename of input file.\n");
    fprintf(stderr, "calcProChkSum <file name of binary file>\n");
    fprintf(stderr, "Program will output to stdout.\n");
    exit(1);
  }

  memcpy(memory, romHeader, 26);
  memory[0] = id & 0xff;
  memory[1] = (id >> 8) & 0xff;
  memory[6] = 0xff & memorySize;

  in = fopen (argv[1], "r");

  fstat(fileno(in), &s);
  fileSize = s.st_size;

  memory[23] = (fileSize+2) & 0xff;
  memory[24] = ((fileSize+2) >> 8) & 0xff;
  for (i=0; i < fileSize; i++) {
    memory[i+26] = fgetc(in);
  }

  checksum = calcChecksum(memory+26, fileSize);
  memory[26+fileSize] = checksum & 0xff;
  memory[26+fileSize+1] = (checksum>>8) & 0xff;
  checksum = calcChecksum(memory, (memorySize * 256)-2);

  memory[memorySize*256-2] = checksum & 0xff;
  memory[memorySize*256-1] = (checksum >> 8) & 0xff;

  for (i=0; i < (memorySize * 256); i++) {
    putchar(memory[i]);
  }
  return 0;
}
