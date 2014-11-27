*-----------------------------------------------------------
* Title      : Move EA Test
* Written by : John Louie
* Date       : 11-16-14
* Description: Testing Move EA
*-----------------------------------------------------------

;=================================================;
;----- Variables to identify modes/registers -----;
;=================================================;
Dn_Mode             EQU     %000
An_Mode             EQU     %001
An_Pntr_Mode        EQU     %010
An_Inc_Mode         EQU     %011
An_Dec_Mode         EQU     %100
Word_Mode           EQU     %111
Word_Reg            EQU     %000
Long_Mode           EQU     %111
Long_Reg            EQU     %001
Imm_Mode            EQU     %111
Imm_Reg             EQU     %100

;==============================================;
;--------------- Test variables ---------------;
;==============================================;
Test_Move1          EQU     %0001010000000001   ; Move.B D1,D2
Test_Move2          EQU     %0001010001000100   ; Move.B A2,D4 INCORRECT
Test_Move3          EQU     %0001111010010000   ; Move.B (A0),(A7)
Test_Move4          EQU     %0001111011100010   ; Move.B -(A2),(A7)+
Test_Move5          EQU     %0001001000111000   ; Move.B $Word,D1
Test_Move6          EQU     %0001111000111001   ; Move.B $Long,D7
Test_Move7          EQU     %0011010010111100   ; Move.W #$Imm,(A2)
Test_Move8          EQU     %0010111100111100   ; Move.L #$Imm,-(A7)

Add_Test1           EQU     %1101111011000001   ; AddA.W D1,A7
Add_Test2           EQU     %1101100001111100   ; Add.W #$Imm,D4
Add_Test3           EQU     %1101111101010111   ; Add.W D7,(A7)
Add_Test4           EQU     %1101111111111001   ; AddA.L $Long,A7

Shift_Test1         EQU     %1110000111010111   ; Asl (A7)
Shift_Test2         EQU     %1110000111111000   ; Asl $Word
Shift_Test3         EQU     %1110111100100001   ; Asl.B D7,D1
Shift_Test4         EQU     %1110010100000111   ; Asl.B #2,D7
Shift_Test5         EQU     %1110000100000100   ; Asl.B #8,D4

Imm_Test1           EQU     %0000010000011111   ; SubI.B #$Imm,(A7)+
Imm_Test2           EQU     %0000010001111001   ; SubI.W #$Imm,$Long

AddQ_Test1          EQU     %0101111000001001   ; AddQ.B #7,A1
AddQ_Test2          EQU     %0101000000001001   ; AddQ.B #8,A1

Muls_Test1          EQU     %1100111111111100   ; Muls.W #$Imm,D7
Muls_Test2          EQU     %1100111111010010   ; Muls.W (A2),D7

Btst_Test1          EQU     %0000111100000111   ; Btst D7,D7
Btst_Test2          EQU     %0000111100111100   ; Btst D7,#$Imm
Btst_Test3          EQU     %0000100000000111   ; Btst #$Byte,D7
        
    ORG    $1000
    
START:                  ; first instruction of program
        Move.L  #$0000400, A3
        
        Move.W  #$0034, (A3)
        ;Move.W  #$4030, (A3)+
        ;Move.L  #$12345678, (A3)
        ;Sub.W   #2, A3
        ;Move.L  #$12349999, (A3)
        ;Move.W  #$11, (A3)
        ;Move.B  #$99, (A3)
        
        ;Move.W  #Test_Move1, D4
        ;Move.W  #Test_Move2, D4
        ;Move.W  #Test_Move3, D4
        ;Move.W  #Test_Move4, D4
        ;Move.W  #Test_Move5, D4
        ;Move.W  #Test_Move6, D4        
        ;Move.W  #Test_Move7, D4        
        ;Move.W  #Test_Move8, D4
        
        ;Move.W  #Add_Test1, D4
        ;Move.W  #Add_Test2, D4
        ;Move.W  #Add_Test3, D4
        ;Move.W  #Add_Test4, D4
        
        ;Move.W  #Shift_Test1, D4
        ;Move.W  #Shift_Test2, D4
        ;Move.W  #Shift_Test3, D4
        ;Move.W  #Shift_Test4, D4
        ;Move.W  #Shift_Test5, D4
        
        ;Move.W  #Imm_Test1, D4
        ;Move.W  #Imm_Test2, D4
        
        ;Move.W  #AddQ_Test1, D4
        ;Move.W  #AddQ_Test2, D4
        
        ;Move.W  #Muls_Test1, D4
        ;Move.W  #Muls_Test2, D4
        
        ;Move.W  #Btst_Test1, D4
        ;Move.W  #Btst_Test2, D4
        Move.W  #Btst_Test3, D4
                
        ;Jmp     EA_MOVE     ; Branch to EA function for Move
        ;Jmp     EA_ADD
        ;Jmp     EA_BIT_SHIFT
        ;Jmp     EA_IMMEDIATE
        ;Jmp     EA_ADDQ
        ;Jmp     EA_MULS
        Jmp     EA_BTST

;]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]];  
;-------------------- Effective Address Sub Routines --------------------;
; These subroutines look for the correct effective address
; in each OP code.
;]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]];

;=============================================;
;--------------- EA Move/MoveA ---------------;
;=============================================;
EA_MOVE
        Jsr     EA_MOVE_SOURCE          ; Add the EA for source
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_MOVE_DEST            ; Add the EA for destination
        
        ; <Next instruction>
                
EA_MOVE_SOURCE  ; Find out Move's source
        Jsr     EA_0TO5                 ; Get the EA
        
        Cmp.B   #Imm_Reg, D0            ; #<data>
        Beq     EA_MOVE_SIZE
        
        Rts
        
EA_MOVE_DEST    ; Find out Move's destination
        Jsr     GET6TO8                 ; Get destination mode
        Move.B  D0, D5                  ; Move destination mode to D5
        Jsr     GET9TO11                ; Get destination register
        
        ; List of valid effective addresses
        Cmp.B   #Dn_Mode, D5            ; Dn
        Beq     EA_DN
        
        Cmp.B   #An_Mode, D5            ; An
        Beq     EA_AN
        
        Cmp.B   #An_Pntr_Mode, D5       ; (An)
        Beq     EA_AN_PNTR
        
        Cmp.B   #An_Inc_Mode, D5        ; (An)+
        Beq     EA_AN_INC
        
        Cmp.B   #An_Dec_Mode, D5        ; -(An)
        Beq     EA_AN_DEC
        
        ; Comparing registers at this point because modes are the same
        Cmp.B   #Word_Reg, D0           ; (xxx).W
        Beq     EA_WORD_ADDR
        
        Cmp.B   #Long_Reg, D0           ; (xxx).L
        Beq     EA_LONG_ADDR
        
        Rts
        
EA_MOVE_SIZE    ; Find the size of immediate data being moved
        Jsr     GET12TO13               ; Get Move size

        Cmp.B   #%01, D0                ; Byte
        Beq     EA_IMM_BYTE

        Cmp.B   #%11, D0                ; Word
        Beq     EA_IMM_WORD
        
        Cmp.B   #%10, D0                ; Long
        Beq     EA_IMM_LONG
        
        Rts

;===========================================;        
;--------------- EA Add/AddA ---------------;
;===========================================;       
EA_ADD  ; Figures out the EA for Add        
        Jsr     GET6TO8                 ; Isolate the Op mode
        
        Cmp.B   #%011, D0               ; Compare to AddA word
        Beq     EA_ADDA
        
        Cmp.B   #%111, D0               ; Compare to AddA long
        Beq     EA_ADDA

        Cmp.B   #%000, D0               ; Compare to Add source byte
        Beq     EA_ADD_OPMODE_SOURCE
        
        Cmp.B   #%001, D0               ; Compare to Add source word
        Beq     EA_ADD_OPMODE_SOURCE
        
        Cmp.B   #%010, D0               ; Compare to Add source Long
        Beq     EA_ADD_OPMODE_SOURCE
        
        Jmp     EA_ADD_OPMODE_DEST      ; Must be an Add destination if none of the above
        
EA_ADDA ; Figures out the EA for AddA
        Jsr     EA_ADD_ADDRESS          ; Get the source EA
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     GET9TO11                ; Get the register
        Jsr     EA_AN                   ; Add An
        
        ; <Next instruction>
        
EA_ADD_OPMODE_SOURCE    ; Finds the EA for Add if it is for the source
        Jsr     EA_ADD_ADDRESS          ; Get the source EA
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     GET9TO11                ; Get the register
        Jsr     EA_DN                   ; Add Dn
        
        ; <Next instruction>
        
EA_ADD_OPMODE_DEST      ; Finds the EA for Add if it is for the destination
        Jsr     GET9TO11                ; Get the register
        Jsr     EA_DN                   ; Add Dn
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_ADD_ADDRESS          ; Get the destination EA 
        
        ; <Next instruction>
        
EA_ADD_ADDRESS
        Jsr     EA_0TO5                 ; Check for all EA except #<data>
        
        Cmp.B   #Imm_Reg, D0            ; #<data>
        Beq     EA_ADD_SIZE

        Rts
        
EA_ADD_SIZE ; Find the size of immediate data being moved
        Jsr     GET6TO8                 ; Get Move size

        Cmp.B   #%000, D0               ; Byte
        Beq     EA_IMM_BYTE

        Cmp.B   #%001, D0               ; Word
        Beq     EA_IMM_WORD
        
        Cmp.B   #%010, D0               ; Long
        Beq     EA_IMM_LONG
        
        Cmp.B   #%011, D0               ; AddA Word
        Beq     EA_IMM_WORD
   
        Cmp.B   #%111, D0               ; AddA Long
        Beq     EA_IMM_LONG
        
        Rts
        
;=================================================;        
;-------------------- EA AddQ --------------------;
;=================================================;
EA_ADDQ ; Figures out the EA for AddQ
        Jsr     EA_ADDQ_CHECK_8         ; Get the immediate value
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_ADDQ_DEST            ; Add the destination

EA_ADDQ_CHECK_8 ; A bit value of 1-7 corresponds to 1-7, but 0 corresponds to 8
        Jsr     GET9TO11                ; Isolate the count/register bits
        
        Cmp.B   #0, D0                  ; If the bits are greater than 0, proceed normally
        Bgt     EA_ADDQ_IMMEDIATE
        
        Move.B  #8, D0                  ; Else, use 8 as the immediate value
        
        Jmp     EA_ADDQ_IMMEDIATE
        
EA_ADDQ_IMMEDIATE   ; Adds an immediate value before the comma
        Move.B  #'#', (A6)+
        Add.B   #$30, D0
        Move.B  D0, (A6)+               ; Add the immediate value to the string
        
        Rts
        
EA_ADDQ_DEST    ; Determines the destination       
        Jsr     EA_0TO5                 ; Check for all EA except #<data>
        
;=========================================================;        
;---------------------- EA Sub/SubA ----------------------;
; Jumps straight to EA_ADD because the EA for Add/AddA and
; Sub/SubA are exactly the same.
;=========================================================;
EA_SUB
        Jmp     EA_ADD

;=========================================================;        
;---------------------- EA Cmp/CmpA ----------------------;
; Jumps straight to EA_ADD because the EA for Add/AddA and
; Cmp/CmpA are exactly the same.
;=========================================================;
EA_CMP       
        Jmp     EA_ADD
        
;=========================================================;        
;------------------------ EA Lea -------------------------;
; Jumps straight to EA_ADD because the EA for AddA and Lea
; are exactly the same.
;=========================================================;
EA_LEA
        Jmp     EA_ADD
        
;=========================================================;        
;------------------------ EA And -------------------------;
; Jumps straight to EA_ADD because the EA for Add and And
; are exactly the same.
;=========================================================;
EA_AND
        Jmp     EA_ADD
        
;=========================================================;        
;------------------------ EA Eor -------------------------;
; Jumps straight to EA_ADD because the EA for Add and Eor
; are exactly the same.
;=========================================================;
EA_EOR
        Jmp     EA_ADD
        
;=========================================================;        
;------------------------ EA Neg -------------------------;
;=========================================================;
EA_NEG
        Jsr     EA_0TO5                 ; Check for all EA except #<data>
        
        ; <Next instruction>
        
;=========================================================;        
;------------------------ EA Not -------------------------;
; Jumps straight to EA_NEG because Neg and Not have the
; exact same EAs. 
;=========================================================;
EA_NOT
        Jmp     EA_NEG 

;=========================================================;
;--------------------- EA Bit Shift ----------------------;
; Finds the EA for ASd, LSd, ROd. All of these OP codes
; are combined because the EA for each code is exactly the
; same.
;=========================================================;
EA_BIT_SHIFT    ; Figures out the EA for bit shift functions
        Jsr     GET6TO7
        
        Cmp.B   #%11, D0                ; If bits 6 and 7 are not %11, then we are shifting a register
        Bne     EA_SHIFT_REGISTER
        
        Jsr     EA_SHIFT_MEMORY         ; If bits 6 and 7 are %11, then we are shifting memory
        
        ; <Next instruction>
                
EA_SHIFT_MEMORY ; Adds the correct EA for a memory shift
        Jsr     EA_0TO5                 ; Check for all EA except #<data>
        
EA_SHIFT_REGISTER   ; Figure out if we are shifting by #<data> or by the value in a data register
        Jsr     GETBIT5
        
        Cmp.B   #0, D0                  ; Check if bit 5 is %0
        Beq     EA_SHIFT_CHECK_8
        
        Jmp     EA_SHIFT_DN             ; If it's not, we are shifting from a data register
        
EA_SHIFT_CHECK_8    ; A bit value of 1-7 corresponds to 1-7, but 0 corresponds to 8
        Jsr     GET9TO11                ; Isolate the count/register bits
        
        Cmp.B   #0, D0                  ; If the bits are greater than 0, proceed normally
        Bgt     EA_SHIFT_IMMEDIATE
        
        Move.B  #8, D0                  ; Else, use 8 as the immediate value
                
        Jmp     EA_SHIFT_IMMEDIATE
        
EA_SHIFT_IMMEDIATE  ; Adds an immediate value before the comma
        Move.B  #'#', (A6)+
        Add.B   #$30, D0
        Move.B  D0, (A6)+               ; Add the immediate value to the string

        Jmp     EA_SHIFT_COMMA          ; Add the comma and everything after it
        
EA_SHIFT_DN ; Adds a data register before the comma
        Jsr     GET9TO11                ; Isolate the data register bits
        
        Jsr     EA_DN                   ; Add the data register to the string
        
        Jmp     EA_SHIFT_COMMA          ; Add the comma and everything after it 
        
EA_SHIFT_COMMA  ; Adds the comma and everything after it to the string
        Move.B  #',', (A6)+
        
        Jsr     GET0TO2                 ; Get the register number
        
        Jsr     EA_DN                   ; Add the register
        
        ; <Next instruction>

;============================================;        
;--------------- EA Immediate ---------------;
; Provides EA for SubI, OrI, EorI, and CmpI.
;============================================;
EA_IMMEDIATE    ; Figures out the EA for immediate data OP codes
        Jsr     EA_IMMEDIATE_SIZE       ; Get the size of the immediate data and add to string
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_IMMEDIATE_DEST       ; Add the destination EA
        
        ; <Next instruction>
        
EA_IMMEDIATE_SIZE   ; Determines the size of the immediate data and adds it
        Jsr     GET6TO7                 ; Isolate the size bits
                
        Cmp.B   #%01, D0                ; Immediate word
        Beq     EA_IMM_WORD
        
        Cmp.B   #%10, D0                ; Immediate long
        Beq     EA_IMM_LONG
        
        AddA.W  #1, A3                  ; Else, move the pointer forward by a byte to get the next byte
        Jmp     EA_IMM_BYTE

        Rts
        
EA_IMMEDIATE_DEST   ; Determines the destination EA
        Jsr     EA_0TO5                 ; Check for all EA except #<data>
      
;=================================================;  
;-------------------- EA Muls --------------------;
;=================================================;
EA_MULS ; Determines the EA for Muls
        Jsr     EA_MULS_ADDRESS         ; Get the EA
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     GET9TO11                ; Get the register
        Jsr     EA_DN                   ; Add Dn
        
        ; <Next instruction>
        
EA_MULS_ADDRESS ; Determines the EA
        Jsr     EA_0TO5                 ; Check for all EA except #<data>
        
        Cmp.B   #Imm_Reg, D0            ; Check for #<data>
        Beq     EA_IMM_WORD
        
        Rts
        
;=================================================;  
;-------------------- EA DIVS --------------------;
; Jumps straight to EA_DIVS because the EA for
; both OP codes is exactly the same.
;=================================================;
EA_DIVS
        Jmp     EA_MULS
        
;=================================================;        
;-------------------- EA BTST --------------------;
;=================================================;
EA_BTST ; Determines the EA for Btst
        Jsr     GETBIT8                 ; Use bit 8 to determine if the bit number is immediate or a data register
        
        Cmp.B   #%1, D0                 ; 1 is a data register
        Beq     EA_BTST_DN
        
        Jmp     EA_BTST_IMM             ; Else (0), the bit number is immediate data
        
EA_BTST_DN  ; Gets the register for the bit number
        Jsr     GET9TO11                ; Get the register
        Jsr     EA_DN                   ; Add the register to the string
        
        Jsr     EA_BTST_ADDRESS         ; Add the EA
        
        ; <Next instruction>

EA_BTST_IMM ; Gets the immediate data for the bit number
        AddA.W  #1, A3                  ; Move the pointer forward by a byte to get the next byte
        Jsr     EA_IMM_BYTE             ; Add the bit number as an immediate hex byte
        
        Jsr     EA_BTST_ADDRESS         ; Add the register to the string
        
        ; <Next instruction>

EA_BTST_ADDRESS ; Get the EA
        Move.B  #',', (A6)+

        Jsr     EA_0TO5                 ; Check the EA for everything but #<data>
        
        Cmp.B   #Imm_Reg, D0            ; Check if the EA is #<data>
        Beq     EA_IMM_BYTE             ; Add immediate byte for EA
        
        Rts
               
;==========================================;        
;---------- General EA functions ----------;
;==========================================;
EA_DN   ; Adds Dn EA to string
        Move.B  #'D', (A6)+             
        Add.B   #$30, D0        
        Move.B  D0, (A6)+               
                
        Rts

EA_AN   ; Adds An EA to string
        Move.B  #'A', (A6)+
        Add.B   #$30, D0    
        Move.B  D0, (A6)+               
                
        Rts

EA_AN_PNTR  ; Adds (An) EA to string
        Move.B  #'(', (A6)+
        Move.B  #'A', (A6)+
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        Move.B  #')', (A6)+
                
        Rts
        
EA_AN_INC   ; Adds (An)+ EA to string
        Move.B  #'(', (A6)+
        Move.B  #'A', (A6)+
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        Move.B  #')', (A6)+
        Move.B  #'+', (A6)+
                
        Rts 
        
EA_AN_DEC   ; Adds -(An) EA to string
        Move.B  #'-', (A6)+
        Move.B  #'(', (A6)+
        Move.B  #'A', (A6)+
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        Move.B  #')', (A6)+
                
        Rts 

EA_WORD_ADDR    ; Adds $Word to string
        Move.W  (A3)+, D6           ; Move the word address into D6 and move forward in memory
        
        Move.B  #'$', (A6)+
        
        Cmp.W   #$8000, D6          ; Word address is less than 8000
        Bgt     EA_SIGN_EXT_16
        
        Cmp.W   #$8000, D6          ; Word address is greater than 8000
        Ble     EA_SIGN_EXT_32
        
        Rts
                
EA_SIGN_EXT_16  ; Adds 0 if the word address is 16 bit
        Move.B  #'0', (A6)+
        Move.B  #'0', (A6)+
        Move.B  #'0', (A6)+
        Move.B  #'0', (A6)+
        
        Jsr     EA_WORD_TO_STRING       
        
        Rts

EA_SIGN_EXT_32 ; Adds F is the word address is 32 bit
        Move.B  #'F', (A6)+
        Move.B  #'F', (A6)+
        Move.B  #'F', (A6)+
        Move.B  #'F', (A6)+
        
        Jsr     EA_WORD_TO_STRING   
        
        Rts
        
EA_WORD_TO_STRING   ; Adds the word in D6 to the string
        Clr.L   D0              ; Clear D0
        Move.W  D6, D0          ; Move the word into D0 so it can be shifted

        Move.B  #12, D1         ; Grab bits 12 to 15
        Lsr     D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0
        Move.W  D6, D0
        
        Move.B  #4, D1          ; Grab bits 8 to 11
        Lsl     D1, D0
        Move.B  #12, D1
        Lsr     D1, D0  
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0
        Move.W  D6, D0
        
        Move.B  #8, D1          ; Grab bits 4 to 7
        Lsl     D1, D0
        Move.B  #12, D1
        Lsr     D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0
        Move.W  D6, D0
        
        Move.B  #12, D1         ; Grab bits 0 to 3
        Lsl     D1, D0
        Move.B  #12, D1
        Lsr     D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Rts
        
EA_LONG_ADDR    ; Adds $Long to string
        Move.L  (A3)+, D6           ; Move the long address into D6 and move forward in memory
        
        Move.B  #'$', (A6)+
        
        Jsr     EA_LONG_TO_STRING

        Rts
                
EA_LONG_TO_STRING   ; Adds the long in D6 to the string
        Clr.L   D0              ; Clear D0
        Move.L  D6, D0          ; Move the long into D0 so it can be shifted

        Move.B  #28, D1         ; Grab bits 28 to 31
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0          
        
        Move.B  #4, D1          ; Grab bits 24 to 27
        Lsl.L   D1, D0
        Move.B  #28, D1
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0

        Move.B  #8, D1          ; Grab bits 20 to 23
        Lsl.L   D1, D0
        Move.B  #28, D1
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0

        Move.B  #12, D1         ; Grab bits 16 to 19
        Lsl.L   D1, D0
        Move.B  #28, D1
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0

        Move.B  #16, D1         ; Grab bits 12 to 15
        Lsl.L   D1, D0
        Move.B  #28, D1
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0
        
        Move.B  #20, D1         ; Grab bits 8 to 11
        Lsl.L   D1, D0
        Move.B  #28, D1
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0

        Move.B  #24, D1         ; Grab bits 4 to 7
        Lsl.L   D1, D0
        Move.B  #28, D1
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0

        Move.B  #28, D1         ; Grab bits 0 to 3
        Lsl.L   D1, D0
        Move.B  #28, D1
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Rts
        
EA_BYTE_TO_STRING   ; Adds the byte in D6 to the string
        Clr.L   D0              ; Clear D0
        Move.L  D6, D0          ; Move the byte into D0 so it can be shifted

        Move.B  #4, D1          ; Grab bits 4 to 7
        Lsr.B   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0          
        
        Move.B  #4, D1          ; Grab bits 0 to 3
        Lsl.B   D1, D0
        Move.B  #4, D1
        Lsr.B   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Rts

EA_IMM_BYTE ; Finds the immediate byte data
        Move.B  (A3)+, D6            ; Move the immediate byte data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+         
        Move.B  #'$', (A6)+         
        
        Jsr     EA_BYTE_TO_STRING    ; Add the byte to the string
        
        Rts
                
EA_IMM_WORD ; Finds the immediate word data
        Move.W  (A3)+, D6            ; Move the immediate word data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+         
        Move.B  #'$', (A6)+         
        
        Jsr     EA_WORD_TO_STRING    ; Add the word to the string
        
        Rts
        
EA_IMM_LONG ; Finds the immediate long data
        Move.L  (A3)+, D6            ; Move the immediate long data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+
        Move.B  #'$', (A6)+
        
        Jsr     EA_LONG_TO_STRING    ; Add the long to the string
        
        Rts
        
EA_0TO5 ; Determines the EA for an EA in bits 0-5. DOES NOT HANDLE IMMEDIATE VALUES.
        Jsr     GET3TO5                 ; Get source mode
        Move.B  D0, D5                  ; Move source mode to D5
        Jsr     Get0TO2                 ; Get source register
        
        ; List of valid effective addresses
        Cmp.B   #Dn_Mode, D5            ; Dn
        Beq     EA_DN
        
        Cmp.B   #An_Mode, D5            ; An
        Beq     EA_AN
        
        Cmp.B   #An_Pntr_Mode, D5       ; (An)
        Beq     EA_AN_PNTR
        
        Cmp.B   #An_Inc_Mode, D5        ; (An)+
        Beq     EA_AN_INC
        
        Cmp.B   #An_Dec_Mode, D5        ; -(An)
        Beq     EA_AN_DEC
        
        ; Comparing registers at this point because modes are the same
        Cmp.B   #Word_Reg, D0           ; (xxx).W
        Beq     EA_WORD_ADDR
        
        Cmp.B   #Long_Reg, D0           ; (xxx).L
        Beq     EA_LONG_ADDR
        
        Rts
        
;===========================================================;       
;---------------- Bit Chopping Sub Routines ----------------;
; These Sub Routines Chop a WORD size piece of data from
; Data register 4 into a smaller piece, leaving just the
; Piece in register 0 while leaving the original piece
; of data intact.
;===========================================================;
GET12TO15
		CLR.L	D0
		Move.W 	D4, D0
				
		Move.B	#12, D1
		LSR	    D1, D0
				
		RTS

GET12TO13
        CLR.L   D0
        Move.W  D4, D0
        
        Move.B  #2, D1
        LSL     D1, D0
        
        Move.B  #14, D1
        LSR     D1, D0
        
        RTS
				
GET9TO11		
		CLR.L	D0
		Move.W 	D4, D0
				
		Move.B	#4, D1
		LSL  	D1, D0
				
		Move.B	#13, D1
		LSR	    D1, D0
				
		RTS
				
GET6TO8	
		CLR.L	D0
		Move.W 	D4, D0
				
		Move.B	#7, D1
		LSL  	D1, D0
				
		Move.B	#13, D1
		LSR	    D1, D0
				
		RTS
				
GET3TO5	
		CLR.L	D0
		Move.W 	D4, D0
				
		Move.B	#10, D1
		LSL  	D1, D0
				
		Move.B	#13, D1
		LSR	    D1, D0
				
		RTS
GET0TO2	
		CLR.L	D0
		Move.W 	D4, D0
				
		Move.B	#13, D1
		LSL  	D1, D0
				
		Move.B	#13, D1
		LSR	    D1, D0
				
		RTS
GETBIT8
		CLR.L	D0
		Move.W 	D4, D0
				
		Move.B	#7, D1
		LSL  	D1, D0
				
		Move.B	#15, D1
		LSR	    D1, D0
				
		RTS 
		
GET6TO7
        Clr.L   D0
        Move.W  D4, D0
        
        Move.B  #8, D1
        Lsl     D1, D0
        
        Move.B  #14, D1
        Lsr     D1, D0
        
        Rts
        
GETBIT5
        Clr.L   D0
        Move.W  D4, D0
        
        Move.B  #10, D1
        Lsl     D1, D0
        
        Move.B  #15, D1
        Lsr     D1, D0
        
        Rts


    END    START        ; last line of source













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
