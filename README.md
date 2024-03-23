# DECPROMEM

![Original PRO mem  board](OriginalBoard.jpeg)
This project aims at creating a modern memory board for the 1985 vintage DEC Professional series of computers with CTI bus. The idea is to use SRAM technology and programmable logic to implement all the random logic needed. The diagnostic ROM that all CTI bus boards need to have is implemented in a SPI EEPROM chip. The programmable logic choosen for this project is the Atmel / Microchip ATF1508 since it is the only contemporary chip that is 5V. I will be using one or two 1Mx16 SRAM chip which also are 5V. A small SPI EEPROM will contain the diag software. There will not be any parity on board whihc means that the diag software need to be changed compared to the original so that it doesn't test the parity generating and checking circuits on board.

The idea with this project is also to learn a bit about the CTI bus so that I can take on the DECNA-replica project later on which aims at creating a modern replacement for the DECNA board whihc is nearly impossible to find. This will also be using a ATF1508 CPLD.

## Firmware

The original diagnostic firmware is stored in either a 2716 or 2732 (jumper selectable on the board according to the manual), but only the lower 1k byte is actually used. 

I have been using xhomer project which I modified to create an execution trace. Thereby I could figure out how the Professional is dealing with CTI bus boards.
All boards has a board ID which identify the board. This is a two byte octal number which is also printed on the board handle. The memory board is 34 for example. Most likely the board id has significance to how the board is handled but I have obnly researched the memory board this far.

All CTI bus boards have a writeable register located at base address + 2 which resets the pointer to the ID / diagnostic ROM when written to it. Then reads from the base address will return byte by byte from the ID / diag ROM. The process is the following:

1. Read the two ID bytes. Decide how to handle board.
2. Reset pointer and read the first 12 bytes into memory. Byte 2 is compared with 0377. I am not sure what happens if it is not matching. Then it uses byte 6 to indicate the number of 128 word blocks that are present in the memory.
3. It resets the pointer again and start reading the number indicated byte location 6 above of 128 word blocks and calculates a checksum. More on the checksum algorithm later.
4. It then resets the pointer again and just read and skip the first 12 bytes. Then it reads in the following 14 bytes.
5. Location 23 and 24 is the size of the actual program code following, where byte 23 is the low byte and 24 is the high byte. The resuling 16 bit integer is then used when reading in the program code.
6. While reading the program code the same type of checksum is calculated again over this smaller block.

### Checksum algorithm

The checksum algorithm is a combination of xor and shift operations.
1. A checksum accumulator is initiated to 0177777
2. Two bytes are read in to form a word.
3. The data is xor:ed with the accumulator contents.
4. The accumulator is shifted on step to the left.
5. The bit overflowing 16 bits is creating a carry bit which either one or zero.
6. The carry bit is added to the accumulator.
7. The process repeats at 2 until all words has been read.
8. If the result in the accumulator is zero when all words has vbeen read then we have a good checksum.

### Firmware functions

The firmware is used to initialize and test the board. The process is the following:
1. Calculates the size of the board. There are two jumpers on the board which give the actual size of the board. I think actually this calculation is buggy for boards with 256 k chips!
2. It compares the calculated size with the value used as base value for this memory array. If the base address indicate that we already configured 3 Megabytes of memory we bail out with an error code.
3. Enable the memory board with the base value given from the system.
4. If memory size of the board give that it will exceed the 3 meg limit it tests so that there is no response from the memory for addresses aboev 3 meg.
5. It now enables the functionaity where  the memory board by design writes the oposite parity value which means that a read will cause a trap, thereby checking so that the parity circuits work.
6. Sets back to normal partity handling and checks the entire array.
7. If everything is ok it reports back the new base value which is essentially the old base value plus the size of this memory array. If something wrong has been detected then it will turn off the memory board and issue a fault code as return value.
   

