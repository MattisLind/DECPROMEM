#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>

#define IDLE 0
#define BYTECOUNT 1
#define ADDRESS 2
#define RECORDTYPE 3
#define DATA 4
#define CHECKSUM 5

#define TYPE_6300 1
#define TYPE_6330 2
#define TYPE_1702 3

#define WIDTH_8BIT 1
#define WIDTH_4BIT 2

int printROMProlog(char * entity) {
  printf("-- Standard Bipolar 256 x 4 bit PROM \n");
  printf("library IEEE;\n");
  printf("use IEEE.std_logic_1164.all;\n");
  printf("use ieee.numeric_std.all;\n");
  printf("\n");
  printf("entity %s is\n",entity);
  printf("port(\n");
  printf("  address  : in integer range 0 to 1023;\n");
  printf("  bitAddress : in integer range 0 to 7;\n");
  printf("  data     : out std_logic);\n");
  printf("end %s;\n", entity);
  printf("\n");
  printf("architecture logic of %s is\n",entity);
  printf("type rom_type is array (0 to 1023) of std_logic_vector(7 downto 0); \n");
  printf("signal dataFromRom: std_logic_vector(7 downto 0);\n");
  printf("signal rom : rom_type := ( \n");
  printf("\n");
}

int printROMEpilog() {
  printf (");\n");
  printf("\n");
  printf("begin\n"); 
  printf("\n");
  printf("  dataFromRom <= rom(address);\n");
  printf("  data <= dataFromRom(7-bitAddress); \n");
  //printf("\n");
  printf("end logic;\n");
}


int main (int argc, char **argv) {
  int c, i=0;
  char entity [32];
  
  while (1) {
    int this_option_optind = optind ? optind : 1;
    int option_index = 0;
    static struct option long_options[] = {
					   {"entity",     required_argument, 0,  0 },
					   {0,         0,                 0,  0 }
    };
    
    c = getopt_long(argc, argv, "e:",
		    long_options, &option_index);
    if (c == -1)
      break;
    
    switch (c) {
    case 0:
      switch (option_index) {
      case 0: // entity
	      strncpy(entity, optarg,32);
	    break;
      }
      break;
      
    case 'e':
      strncpy(entity, optarg,32);
      break;
      
      
    default:
      fprintf(stderr, "?? getopt returned character code 0%o ??\n", c);
    }
  }
  
  if (optind < argc) {
    fprintf(stderr, "non-option ARGV-elements: ");
    while (optind < argc)
      fprintf(stderr, "%s ", argv[optind++]);
    fprintf(stderr, "\n");
  }
  
  printROMProlog(entity);
  while (!feof(stdin)) {
    c = getchar();	
    if (feof(stdin)) continue;
	  printf ("x\"%02X\"",c);
    i++;
    if (i!= 1024) {
      printf(",");
    }
    if (i%16 == 0) {
      printf("\n");
    }

  };
  printROMEpilog();

}
