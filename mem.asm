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
        MOV PC,-(SP)
        ADD #L3064-.,(SP)   
        MOV (SP)+,@#4         ; Setup 2036+1026=3064 as trap 4 vector 
        MOV #340,@#6
        CLR L3274
        MOVB @#117707,L3274   ; copy previous base from system
        MOV R0,L3270          ; R0 is likely to be the slot number which is stored in 3270.
        ASH #7,R0             ; Each slot is 128 bytes 
        ADD #174004,R0        ; R0 now contain the address of the base register
        MOV R0,L3262          ; which is stored into 3262
        ADD #2,R0             ; Add 2 to have the address of the CSR
        MOV R0,L3264          ; and store into 3264
        MOV L3274,@L3262      ; Move the base value into the board base register. This is 040 for a system with 1 meg base memory
        MOV L3274,L3272       ; Move the base value into 3272 as well
        ASL L3272             ; Multiply by 4. 3272 seems to be used when setting up the MMU mapping
        ASL L3272             ; Now we should have 200 here.
        MOV #100,L3266             
        BIT #20,@L3264        ; Check SIZ bit. New module has only 2meg (jumper installed = 0) or 4meg (jumper removed = 1). I.e. 64 (0100) or 128 (0200) 32k blocks.
        BEQ BIG
        MOV #200,L3266
BIG:    MOV L3266,R5          ; Size of board
        ADD L3274,R5          ; Plus base
        MOV #1,@L3264         ; Enable board         
        CMP R5,#140           ; Compare with 3meg limit       
        BLE L2372             ; We are lower than 3 meg limit
        MOV #140,L3266        ; we are over the limit. We cannot use the full size of this memory board.
        SUB L3274,L3266       ; calculate the size that we can use
        TST L3266             ; if we get negative that means that this board can not be used at all!
        BGT L2312             ; if we are higher then we can use a bit of this board to reach the 3 meg limit
        JSR PC,EXIT           ; Illegal configuration; this memory module cannot be configured because the cumulative system RAM already exceeds 3 megabytes.
        .WORD 000002
L2312:  MOV PC,-(SP)
        ADD #L3104-.,(SP)     ; Setup 3104 as trap 4 vector.
        MOV (SP)+,@#4
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
        JSR PC,EXIT           ; A memory error trap failed to occur when addresses higher than the 3 megabyte limit were attempted on a system configuration exceeding that limit by including this module's memory capacity.
        .WORD 000003
L2372:  MOV PC,-(SP)
        ADD #L3064-.,(SP)   
        MOV (SP)+,@#4         ; Setup 2036+1026=3064 as trap 4 vector        
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
        SOB R4,L2670          ; .. loop for 32k segment 
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
L2772:  JSR PC,EXIT           ; Bad data was read from memory
        000005
L3000:  SOB R2,L2760          ; loop reading back memory
        EMT 6
        SOB R4,L2732          ; loop
        JSR PC,EXIT           ; Good exit!
        .WORD 000000
L3064:  CMP (SP)+,(SP)+       ; trap vector 4 goes here. Pop off the PC + flags since we are not coming back.
        JSR PC,EXIT
        .WORD 000006
L3104:  MOV #1,R5             ; trap vector 4 goes here as well sometimes. This is a good trap.
        RTI
EXIT:   EMT 6                 ; is this just address mapping cleanup?
        CLR @L3264
        TST @0(SP)            ; Check the error code
        BNE BADEXIT           ; if not zero we jump past good exit code.
        ADD L3266,L3274       ; Good exit 3266 most likely contain the calculated size of the board and 3274 is the copy of the base
        MOVB L3274,@#117707   ; Here we report back the board size. I.e. new base.
        MOV L3266,-(SP)       ; The size is pushed on to stack
        SWAB (SP)        
        ADD (SP)+,@0(SP)
        MOV #1,@L3264         ; enable the memory board
BADEXIT:MOV L3270,R5          ; 3270 is the slot ID
        ASL R5
        ASL R5
        NEG R5
        MOV @(SP)+,117756(R5) ; Report the error code.
        MOV (SP)+,@#6         ; Restore trap vectors
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
        .END
       
       