        .ASECT
        .=02000
        MOV R0,-(SP)          ; Saving plenty of stuff on the stack to be able to restore later on.
        MOV R1,-(SP)
        MOV R2,-(SP)
        MOV R3,-(SP)
        MOV R4,-(SP)
        MOV R5,-(SP)
        MOV @#4,-(SP)
        MOV @#6,-(SP)
        MOV @#114,-(SP)
        MOV @#116,-(SP)
        MOV PC,-(SP)
        ADD #L3064-.,(SP)   
        MOV (SP)+,@#4         ; Setup 2036+1026=3064 as trap 4 vector 
        MOV #340,@#6
        MOV PC,-(SP)          ; Setup 2056 + 1016 = 3074 as trap 114 vector 
        ADD #L3074-.,(SP)
        MOV (SP)+,@#114
        MOV #340,@#116
        CLR L3274
        MOVB @#117707,L3274   ; copy previous base from system
        MOV R0,L3270          ; R0 is likely to be the slot number which is stored in 3270.
        ASH #7,R0             ; Each slot is 128 bytes 
        ADD #174004,R0        ; R0 now contain the address of the base register
        MOV R0,L3262          ; which is stored into 3262
        ADD #2,R0             ; Add 2 to have the address of the CSR
        MOV R0,L3264          ; and store into 3264
        BIT #306,@L3264       ; Check is reasonable values for CSR, PTEN, WROP, PERR and BERR need to be 0.
        BEQ L2154             ; If everything is fine we jump otherwise we exit with code 1
        JSR PC,L3136          ; The control/status register initialized improperly
        .WORD 000001
L2154:  MOV L3274,@L3262      ; Move the base value into the board base register. This is 040 for a system with 1 meg base memory
        MOV L3274,L3272       ; Move the base value into 3272 as well
        ASL L3272             ; Multiply by 4. 3272 seems to be used when setting up the MMU mapping
        ASL L3272             ; Now we should have 200 here.
        CLR L3266              
        BIT #20,@L3264        ; Check SIZE bit. New module has only 2meg or 4meg. I.e. 64 (0100) or 128 (0200) 32k blocks.
        BEQ L2222
        MOV #4,L3266          ; if size=0 3266 becomes 4 
L2222:  ADD #4,L3266          ; If size=1 3266 becomes 8
        BIT #40,@L3264        ; Check the FPOP bit.
        BEQ L2244           
        ASL L3266             ; Multiply 3266 with two if board is fully populated.
L2244:  MOV L3266,R5          ; Size of board
        ADD L3274,R5          ; Plus base
        CMP R5,#140           ; Comapare with 3meg limit
        BLE L2404             ; We are lower than 3 meg limit
        MOV #140,L3266        ; we are over the limit. We cannot use the full size of this memory board.
        SUB L3274,L3266       ; calculate the size that we can use
        TST L3266             ; if we get negative that means that this board can not be used at all!
        BGT L2312             ; if we are higher then we can use a bit of this board to reach the 3 meg limit
        JSR PC,L3136          ; Illegal configuration; this memory module cannot be configured because the cumulative system RAM already exceeds 3 megabytes.
        .WORD 000002
L2312:  MOV PC,-(SP)
        ADD #570,(SP)         ; Setup 3104 as trap 4 vector.
        MOV (SP)+,@#4
        MOV #1,@L3264
        MOV #20000,R0         ; This is the lowest addres in page 1.
        CLR R5
        MOV #1,-(SP)          ; Use only one page
        MOV #600,-(SP)        ; Is this the 3 meg limit set up here?
        EMT 5                 ; This maybe sets up the address mapping??
        CMP (SP)+,(SP)+
        COM (R0)              ; This will cause a trap apparently. Maybe check address logic of the board? If the board has a size and a base that will make it partly above the 3 meg limit we check the addressing logic.
        EMT 6                 ; Perhaps this remove mapping.
        TST R5                ; If we got a trap the R5 is set to 1 in the trap routine.
        BNE L2372             ; Then we skip else we bail out
        JSR PC,L3136          ; A memory error trap failed to occur when addresses higher than the 3 megabyte limit were attempted on a system configuration exceeding that limit by including this module's memory capacity.
        .WORD 000003
L2372:  MOV PC,-(SP)          ; skip this part since it do the checking parity circuits.
        ADD #L3064-.,(SP)
        MOV (SP)+,@#4         ; 3064 is the trap  4 vector now.
L2404:  MOV PC,-(SP)          ; entry point from 2260 if we have less than 3 meg total memory. We are then staying with the old NONEXMEM handler???
        ADD #L3112-.,(SP)     ; 3112 is the trap 114 vector now.
        MOV (SP)+,@#114
        MOV #7,@L3264         ; Enable the board with the WROP bit set to provoke parity error
        MOV L3272,R3          ; The segment address is stored in 3272 and moved into R3
        MOV #20000,R0         ; First address of segment 1
        MOV @L3264,R5         ; R5 now contain the CSR value
        MOV #1,R4
        BIT #40,@L3264        ; Test FPOP bit.
        BEQ L2456
        ASL R4                ; Multiply R4 by two if fully populated.
L2456:  MOV #1,-(SP)          ; loop here until R4 is 0
        MOV R3,-(SP)
        EMT 5                 ; Set up mapping
        CMP (SP)+,(SP)+
        BIC #100,R5           ; Clear Bank Error bit
        BIT #40,@L3264        ; Test tes FPOP bit
        BEQ L2542
        BIT #20,@L3262        ; Test SIZE bit
        BNE L2530
        BIT #20,R3
        BEQ L2542
        BIS #100,R5
        BR L2542
L2530:  BIT #100,R3
        BEQ L2542
        BIS #100,R5
L2542:  MOV L3266,-(SP)       ; One bank only
        ASL (SP)
        ADD (SP)+,R3
        BIS #200,R5
        CLR (R0)              ; Clear memory at address 0 in memory
        TST (R0)              ; Read it back. This should cause a trap if parity circuits work. The trap routine clears bit 7 in R5 and returns.
        BIT #200,R5           ; If we test bit 7 ..
        BEQ L2576             ; and it is zero then we have a good parity checking function
        JSR PC,L3136          ; otherwise we bail out with error 4
        .WORD 000004
L2576:  BIS #200,R5           ; repeat 
        MOV #401,(R0)         ; with different value
        TST (R0)
        BIT #200,R5           ; same procedure as last time
        BEQ L2624
        JSR PC,L3136          ; bail out if bad parity circuitry.
        .WORD 000004
L2624:  EMT 6                 ; turn off mapping
        SOB R4,L2456          ; Loop for other bank
        BIC #4,@L3264         ; Switch off the WROP bit in CSR
        MOV PC,-(SP)          ; Potential jump to to skip all the parity stuff
        ADD #L3074-.,(SP)   
        MOV (SP)+,@#114       ; Setup 3074 as the trap 114 (parity) vector
        MOV #52525,R1         ; Test pattern
        MOV #125252,R5
        MOV L3272,R3          ; 3272 is the base address in 8k segments.
        MOV L3266,R4          ; 3266 is the size in 32 k segments
L2670:  MOV #20000,R0         ; Loop here until R4 is 0. Set R0 = 0 010 000 000 000 000 in first page
        MOV #4,-(SP)          ; maybe this is the size of the mapping? 4 pages? = 32k bytes
        MOV R3,-(SP)
        EMT 5
        CMP (SP)+,(SP)+       ; Restore stack pointer
        ADD #4,R3             ; increment the mapping value for the next 32 k segment   200 .. 204 .. 210 = 0 100 000 000 000 000 000 000 = 04000000 .. 04100000 .. 04200000
        MOV #40000,R2         ; Loop 16k times = word access gives 32 kbytes memory tested
L2716:  MOV R1,(R0)+          ; Looping on R2, storing test pattern into memory
        SOB R2,L2716          ; .. loop..
        EMT 6                 ; Stop mapping
        SOB R4,L2670          ; .. loop for 8k segment 
        MOV L3266,R4
L2732:  MOV #120000,R0        ; Loop here until R4 is 0 R0 = 1 010 000 000 000 000 
        SUB #4,R3
        MOV #4,-(SP)
        MOV R3,-(SP)
        EMT 5
        CMP (SP)+,(SP)+       ; Restore stack pointer
        MOV #40000,R2
L2760:  CMP R1,-(R0)          ; Read back from memory and check. Loop here until R2 is 0
        BNE L2772
        MOV R5,(R0)           ; storing second pattern
        CMP R5,(R0)           ; and read it back
        BEQ L3000
L2772:  JSR PC,L3136          ; Bad data was read from memory
        000005
L3000:  SOB R2,L2760          ; loop reading back memory
        EMT 6
        SOB R4,L2732          ; loop
        MOV #401,R1           ; Another pattern
        MOV L3266,R4
L3016:  MOV #20000,R0         ; loop here until R4 is 0
        MOV #4,-(SP)
        MOV R3,-(SP)
        EMT 5
        CMP (SP)+,(SP)+       ; Restore stack pointer
        ADD #4,R3
        MOV #40000,R2
L3044:  MOV R1,(R0)           ; loop until R2 = 0.
        TST (R0)+             ; Just do a read. The parity circuits is doing the checking.
        SOB R2,L3044          ; loop
        EMT 6                 ; turn off mapping
        SOB R4,L3016          ; loop
        JSR PC,L3136          ; Good exit!
        .WORD 000000
L3064:  CMP (SP)+,(SP)+       ; trap vector 4 goes here. Pop off the PC + flags since we are not coming back.
        JSR PC,L3136
        .WORD 000006
L3074:  CMP (SP)+,(SP)+       ; trap vector 114 goes here sometimes. We enable this when running the memory test. Pop off the PC + flags since we are not coming back.
        JSR PC,L3136          ; An unexpected memory parity trap occurred.
        .WORD 000007
L3104:  MOV #1,R5             ; trap vector 4 goes here as well sometimes. This is a good trap.
        RTI
L3112:  CMP R5,@L3264         ; trap vector 114 goes here. Make sure that we have a parity error now.
        BEQ L3130             ; jump if parity error
        CMP (SP)+,(SP)+       ; Restore stack pointer. Pop off the PC + flags since we are not coming back.
        JSR PC,L3136
        .WORD 000010
L3130:  BIC #200,R5           ; this code clear parity failure bit before returning...
        RTI
L3136:  EMT 6                 ; is this just address mapping cleanup?
        CLR @L3264
        TST @0(SP)            ; Check the error code
        BNE L3206             ; if not zero we jump past good exit code.
        ADD L3266,L3274       ; Good exit 3266 most likely contain the calculated size of the board and 3274 is the copy of the base
        MOVB L3274,@#117707   ; Here we report back the board size. I.e. new base.
        MOV L3266,-(SP)       ; The size is pushed on to stack
        SWAB (SP)        
        ADD (SP)+,@0(SP)
        MOV #1,@L3264         ; enable the memory board
L3206:  MOV L3270,R5          ; 3270 is the slot ID
        ASL R5
        ASL R5
        NEG R5
        MOV @(SP)+,117756(R5) ; Report the error code.
        MOV (SP)+,@#116       ; Restore trap vectors
        MOV (SP)+,@#114
        MOV (SP)+,@#6
        MOV (SP)+,@#4
        MOV (SP)+,R5          ; Restore registers
        MOV (SP)+,R4
        MOV (SP)+,R3
        MOV (SP)+,R2
        MOV (SP)+,R1
        MOV (SP)+,R0
        EMT 0                 ; Done!
L3262:  .WORD  0
L3264:  .WORD  0
L3266:  .WORD  0
L3270:  .WORD  0
L3272:  .WORD  0
L3274:  .WORD  0
       
       