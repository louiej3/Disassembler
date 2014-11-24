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
Add_Test4           EQU     %1101111111111001   ; AddA.L #$Imm,A7
        
    ORG    $1000
    
START:                  ; first instruction of program
        Move.L  #$0000400, A3

        ;Move.W  #$4030, (A3)
        Move.L  #$12345678, (A3)
        ;Move.L  #$12349999, (A3)
        ;Move.W  #$11, (A3)
        
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
        Move.W  #Add_Test4, D4

                
        ;Jmp     EA_MOVE     ; Branch to EA function for Move
        Jmp     EA_ADD

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
                
EA_MOVE_SOURCE  ; Find out Move's source
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
EA_ADD        
        Jsr     GET6TO8
        
        Cmp.B   #%011, D0
        Beq     EA_ADDA
        
        Cmp.B   #%111, D0
        Beq     EA_ADDA

        Cmp.B   #%000, D0
        Beq     EA_ADD_OPMODE_SOURCE
        
        Cmp.B   #%001, D0
        Beq     EA_ADD_OPMODE_SOURCE
        
        Cmp.B   #%010, D0
        Beq     EA_ADD_OPMODE_SOURCE
        
        Jmp     EA_ADD_OPMODE_DEST
        
EA_ADDA
        Jsr     EA_ADD_SOURCE
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     GET9TO11
        Jsr     EA_AN
        
EA_ADD_OPMODE_SOURCE
        Jsr     EA_ADD_SOURCE
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     GET9TO11
        Jsr     EA_DN
        
EA_ADD_OPMODE_DEST
        Jsr     GET9TO11
        Jsr     EA_DN
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_ADD_DEST
        
EA_ADD_SOURCE   ; Find out Add's source
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
        
        Cmp.B   #Imm_Reg, D0            ; #<data>
        Beq     EA_ADD_SIZE
        
        Rts
        
EA_ADD_DEST ; Find out Add's destination
        Jsr     GET3TO5                 ; Get destination mode
        Move.B  D0, D5                  ; Move destination mode to D5
        Jsr     Get0TO2                 ; Get destination register
        
        ; List of valid effective addresses
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

        Move.B  #4, D1         ; Grab bits 4 to 7
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Clr.L   D0             
        Move.L  D6, D0          
        
        Move.B  #4, D1          ; Grab bits 0 to 3
        Lsl.L   D1, D0
        Move.B  #4, D1
        Lsr.L   D1, D0
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        
        Rts

EA_IMM_BYTE ; Finds the immediate byte data
        Move.B (A3)+, D6            ; Move the immediate byte data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+         
        Move.B  #'$', (A6)+         
        
        Jsr     EA_BYTE_TO_STRING    
        
        Rts
                
EA_IMM_WORD ; Finds the immediate word data
        Move.W  (A3)+, D6            ; Move the immediate word data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+         
        Move.B  #'$', (A6)+         
        
        Jsr     EA_WORD_TO_STRING   ; Add the word to the string
        
        Rts
        
EA_IMM_LONG ; Finds the immediate long data
        Move.L  (A3)+, D6            ; Move the immediate long data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+
        Move.B  #'$', (A6)+
        
        Jsr     EA_LONG_TO_STRING
        
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

    END    START        ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
