#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

int main (int argc, char *argv[]) 
{
  FILE * in;
  struct stat s;
  long long i;
  int acc = 0xffff;

  if (argc != 2) {
    fprintf(stderr, "Wrong number of arguments. Program need one parameter. Filename of input file.\n");
    fprintf(stderr, "bin2abs <file name of binary file>\n");
    fprintf(stderr, "Program will output to stdout.\n");
    exit(1);
  }
  in = fopen (argv[1], "r");

  fstat(fileno(in), &s);



  for (i=0; i < (s.st_size >> 1); i++) {
    int lowByte = fgetc(in);
    int highByte = fgetc(in);
    int carry;
    int data = ((highByte << 8) & 0xff00) | (lowByte & 0xff); 
    acc = acc ^ data;
    acc = acc << 1;
    carry = (acc >> 16) & 1;
    acc = acc + carry;
  }
  printf ("acc=%06o %03o:%03o %04X\n", 0xffff & acc, 0xff & (acc>>8), 0xff & acc, 0xffff & acc);

  return 0;
}
