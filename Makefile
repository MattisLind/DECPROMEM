AS=/Users/mattislind/Downloads/xhomer-2-19-24/bin2abs/macro11/macro11
OBJ2BIN=/Users/mattislind/Downloads/xhomer-2-19-24/bin2abs/macro11/obj2bin/obj2bin.pl
TARGET=mem.rom
CSCALC=calcProChkSum
CC=cc

calcProChkSum: calcProChkSum.c
	$(CC) -o $(CSCALC) $(CSCALC).c

mem.rom: mem.bin
	$(CSCALC) mem.bin > mem.rom

mem.bin: mem.obj
	$(OBJ2BIN) --outfile=$@  --raw  $^

mem.obj:mem.asm
	$(AS) -o mem.obj -l mem.lst mem.asm

.PHONY: clean

clean:
	@rm -f mem.obj mem.bin $(CSCALC)

