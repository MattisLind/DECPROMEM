AS=./macro11/macro11
OBJ2BIN=./obj2bin/obj2bin.pl
TARGET=mem.rom
CSCALC=./calcProChkSum
CC=cc

all: mem.rom

$(AS): 
# This is a bit stupid. The macro11 Makefile is broken so it has to be built twice to get a proper build.
	cd macro11; make; make; cd ..


calcProChkSum: calcProChkSum.c
	$(CC) -o $(CSCALC) $(CSCALC).c

mem.rom: mem.bin calcProChkSum
	$(CSCALC) mem.bin > mem.rom

mem.bin: mem.obj $(OBJ2BIN)
	perl $(OBJ2BIN) --outfile=$@  --raw  $^

mem.obj:mem.asm $(AS)
	$(AS) -o mem.obj -l mem.lst mem.asm

.PHONY: clean

clean:
	@rm -f mem.obj mem.bin $(CSCALC) mem.lst mem.rom
	cd macro11; make clean; cd ..

