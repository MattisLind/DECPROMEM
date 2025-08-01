
all: decpromem


vhds:=testbench.vhdl SPIROM.vhdl SN74LS373.vhdl SN74ALS640.vhdl rom.vhdl DP8307.vhdl decpromem.vhdl cy62167.vhdl ClockGen.vhdl ATF1508.vhdl



decpromem: $(vhds)
	ghdl -a --std=08  $(vhds)
	ghdl -e --std=08  testbench
	ghdl -r --std=08  testbench --vcd=decpromem.vcd

clean:
	$(MAKE) -C STD_TTL_LIB clean
	rm -f *.o
	rm -f *.cf
	rm -f testbench 


.PHONY: clean all