*-----------------------------------------------------------
* Title      : Dissassembler Op-code Tree
* Written by : Curtis Andersson
* Date       : 11/3/14
* Description: Determines the Opcode to the level of word size
*-----------------------------------------------------------
    ORG    $1000
   
START:          ; first instruction of program
        Bra     OP_CODE_TREE

OP_CODE_TREE    ; Parses the Op-Code to find what it is
        Jsr     GET12TO15
        
        Cmp.B     #%0000, D0       ; first 4 is 0000, not enough info Immediates
        Beq     IMMEDIATE_BTST
        
        Cmp.B     #%0001, D0       ; Move.B & MoveA.B
        Beq     OP_MOVE
        
        Cmp.B     #%0011, D0       ; Move.W & MoveA.W
        Beq     OP_MOVE

        Cmp.B     #%0010, D0       ; Move.L & MoveA.L
        Beq     OP_MOVE
        
        Cmp.B     #%0100, D0       ; not enough info, Single OPs
        Beq     SINGLE_OPERATOR_CODES
    
        Cmp.B     #%0110, D0       ; Beqnch conditionals
        Beq     BRANCH_CONDITIONALS
        
        Cmp.B     #%1100, D0       ; not enough info, AND or MULS
        Beq     AND_MULS
        
        Cmp.B     #%1110, D0       ; not enough info, bit shifts
        Beq     BIT_SHIFT
        
        Cmp.B     #%0101, D0       ; Add Quick
        Beq     OP_ADDQ
        
        Cmp.B     #%1000, D0       ; Signed Divide
        Beq     OP_DIVS
        
        Cmp.B     #%1001, D0       ; Sub & SubA
        Beq     OP_SUB
        
        Cmp.B     #%1011, D0       ; Cmp.B & Cmp.BA & Eor
        Beq     CMP_EOR
        
        Cmp.B     #%1101, D0       ; Add & AddA
        Beq     OP_ADD
        
        Bra     ILLEGAL         ; If the first 4 has not been covered, then the code is illegal
        
IMMEDIATE_BTST  ; Continue through Op-code Tree, first 4 are 0000
        
        Jsr     GETBIT8         ; Change out test bits
        
        Cmp.B     #%1, D0          ; Bit test
        Beq     OP_BSTS
        
        Jsr     GET9TO11        ; Change out test bits
        
        Cmp.B     #%000, D0        ; Or I
        Beq     OP_ORI
        
        Cmp.B     #%010, D0        ; Subtract I
        Beq     OP_SUBI
        
        Cmp.B     #%101, D0        ; Exclusive or, I
        Beq     OP_EORI
        
        Bra     ILLEGAL         ; Everything else is uncovered
        
SINGLE_OPERATOR_CODES   ; Continue through Op-code Tree, first 4 are 0100

        Jsr     GETBIT8         ; Change out test bits
        
        Cmp.B     #%1, D0      ; Load effetive address
        Beq     OP_LEA
        
        Jsr     GET9TO11        ; Change out test bits        

        Cmp.B     #%010, D0    ; Negate
        Beq     OP_NEG
       
        Cmp.B     #%011, D0    ; Not
        Beq     OP_NOT
        
        Cmp.B     #%100, D0    ; Move multiple registers Registers -> Memory
        Beq     OP_MOVEM_RTOM
        
        Cmp.B     #%110, D0    ; Move multiple registers Memory -> Registers
        Beq     OP_MOVEM_MTOR
        
        Cmp.B     #%111, D0    ; Not enough info, call JSR_RTS
        Beq     JSR_RTS
        
        Bra     ILLEGAL     ; Everything else is uncovered

JSR_RTS     ; Continue through OP tree, first 4 are 0100, 8-11 are 1110

        Jsr     GET6TO8        ; Change out test bits        

        Cmp.B     #%001, D0    ; Return from subroutine
        Beq     OP_RTS
        
        Cmp.B     #%010, D0    ; Jump to Subroutine
        Beq     OP_JSR
        
        Bra     ILLEGAL     ; Everything else is uncovered

BRANCH_CONDITIONALS     ; All Branch conditionals, and BRA. first 4 are 0110

        Jsr     GET8TO11    ; Change out test bits        

        Cmp.B     #%0000, D0   ; Branch
        Beq     OP_BRANCH      
        
        Cmp.B     #%0010, D0   ; High
        Beq     OP_BRA_HIGH
        
        Cmp.B     #%0011, D0   ; Low/same
        Beq     OP_BRA_LOW
        
        Cmp.B     #%0100, D0   ; Carry Clear
        Beq     OP_BRA_CC
        
        Cmp.B     #%0101, D0   ; Carry Set
        Beq     OP_BRA_CS
        
        Cmp.B     #%0110, D0   ; Not Equal
        Beq     OP_BRA_NE
        
        Cmp.B     #%0111, D0   ; Equal
        Beq     OP_BRA_EQ
        
        Cmp.B     #%1000, D0   ; Overflow Clear
        Beq     OP_BRA_VC
        
        Cmp.B     #%1001, D0   ; Overflow Set
        Beq     OP_BRA_VS
        
        Cmp.B     #%1010, D0   ; Plus
        Beq     OP_BRA_PL
        
        Cmp.B     #%1011, D0   ; Minus
        Beq     OP_BRA_MI
        
        Cmp.B     #%1100, D0   ; Greater than or Equal
        Beq     OP_BRA_GE
        
        Cmp.B     #%1101, D0   ; Less Than
        Beq     OP_BRA_LT
        
        Cmp.B     #%1110, D0   ; Greater Than
        Beq     OP_BRA_GT
        
        Cmp.B     #%1111, D0   ; Less than or Equal
        Beq     OP_BRA_LE
        
        Bra     ILLEGAL     ; Not including False* because it makes no sense

AND_MULS        ; Continue through the Op-code Tree, The first four bits are 1100

        Jsr     GET6TO8        ; Change out test bits        

        Cmp.B     #%111, D0    ; Multiply signed
        Beq     OP_MULS
        
        Bra     OP_AND      ; Probably AND, check more in OP_AND
        
BIT_SHIFT        ; Continue through the Op-code Tree, The first four bits are 1110
        
        ; Determine if the shift is Register or Memory shifting
        
        Jsr     GET6AND7
        
        Cmp.B   #%11, D0        ; If the data size field is 11, its Memory
        Beq     BIT_SHIFT_MEM

        Bra     BIT_SHIFT_REG   ; In all other cases, its register shift

BIT_SHIFT_MEM
        
        Jsr     GET9AND10         ; Change out test bits
        
        Cmp.B     #%00, D0        ; Arithmetic Shifts (Left or Right)
        Beq     OP_AS_MEM
        
        Cmp.B     #%01, D0        ; Logical Shift (Left or Right)
        Beq     OP_LS_MEM
        
        Cmp.B     #%11, D0        ; Rotate (Left or Right)
        Beq     OP_RO_MEM
        
        Bra     ILLEGAL         ; Otherwise it is not an accepted command

BIT_SHIFT_REG
        
        Jsr     GET3AND4        ; Change out test bits
        
        Cmp.B     #%00, D0        ; Arithmetic Shifts (Left or Right)
        Beq     OP_AS_REG
        
        Cmp.B     #%01, D0        ; Logical Shift (Left or Right)
        Beq     OP_LS_REG
        
        Cmp.B     #%11, D0        ; Rotate (Left or Right)
        Beq     OP_RO_REG
        
        Bra     ILLEGAL         ; Otherwise it is not an accepted command
CMP_EOR     ; Continue through the Op-code Tree, The first four bits are 1011     
        
        Jsr     GETBIT8         ; Change out test bits
        
        Cmp.B     #%1, D0         ; If bit 8 is 1, It much be EOR
        Beq     OP_EOR
        
        Bra     OP_CMP          ; Otherwise, it must be Cmp.B or Cmp.BA

;---------------------OP_CODE Functions---------------------;
; These Functions have all determined what Op-code or group
; of op-codes I have. The next goal is to Add to the string
; and call the accompying EA function to get the rest of the
; String

; REGISTERS USED: D0, D4 (const), A6

;-----------------------  MOVE  -----------------------------;
OP_MOVE
    ; start string
    
        Move.B  #'M', (A6)+
        Move.B  #'O', (A6)+
        Move.B  #'V', (A6)+
        Move.B  #'E', (A6)+
    
    ; is it an address move?
        Jsr     GET6TO8     ; Get the mode
        Jsr     OP_CHECK_ADDRESS_VERSION ; Check for A version
        
    ; Check data size, Normally i would call OP_CHECK_DATA_SIZE
    ; But move does not use the Op-mode bits, so i'll do it manually
    
        Jsr     GET12TO15

        ; Jump to a sub routine to get the data, so it returns back correctly
        Jsr     OP_MOVE_DATA
        
        ; Put in tabs
        Jsr     OP_TAB
        
        ; Hand the function off to John
        ;Bra     EA_MOVE        

OP_MOVE_DATA
        
        Cmp     #%0001, D0
        Beq     OP_SET_DATA_BYTE
        
        Cmp     #%0010, D0
        Beq     OP_SET_DATA_LONG
        
        Cmp     #%0011, D0
        Beq     OP_SET_DATA_WORD
        
        Rts
        
OP_ADDQ
    Bra DONE    ; PLACEHOLDER
    
;------------------  DIVIDE SINGED  -------------------------;
    
OP_DIVS
    Bra DONE    ; PLACEHOLDER
    
;-----------------------  SUB  ------------------------------;    
    
OP_SUB
    ; start string
    
        Move.B  #'S', (A6)+
        Move.B  #'U', (A6)+
        Move.B  #'B', (A6)+

     ; Check for address version
        
        Jsr     GET6AND7
        Cmp.B   #%11, D0    ; if both bits are 1 it is an address version
        
        Beq     OP_SUB_ADDR

        ; Don't need to worry about ADDA in V1
        ; Check data size
        Jsr     OP_CHECK_DATA_SIZE
        
        ; Put in tabs
        Jsr     OP_TAB
        
        ;Bra     EA_ADD 
        
OP_SUB_ADDR
        
        Move.B  #'A',(A6)+ ; add to the string
        
        ; Find data size
        
        Jsr     OP_CHECK_DATA_SIZE_ADDR
        
        ; Put in tabs
        Jsr     OP_TAB
        
        ; Handoff
        ;Bra     EA_SUBA
        
;-----------------------  ADD  ------------------------------;

OP_ADD
    ; start string
    
        Move.B  #'A', (A6)+
        Move.B  #'D', (A6)+
        Move.B  #'D', (A6)+

    ; Check for address version
        
        Jsr     GET6AND7
        Cmp.B   #%11, D0    ; if both bits are 1 it is an address version
        
        Beq     OP_ADD_ADDR
        
        ; Don't need to worry about ADDA in V1
        ; Check data size
        Jsr     OP_CHECK_DATA_SIZE
        
        ; Put in tabs
        Jsr     OP_TAB
        
        ;Bra     EA_ADD
        
OP_ADD_ADDR
        
        Move.B  #'A',(A6)+ ; add to the string
        
        ; Find data size
        
        Jsr     OP_CHECK_DATA_SIZE_ADDR
        
        ; Put in tabs
        Jsr     OP_TAB
        
        ; Handoff
        ;Bra     EA_ADDA

OP_BSTS
    Bra DONE    ; PLACEHOLDER
OP_ORI
    Bra DONE    ; PLACEHOLDER
OP_SUBI
    Bra DONE    ; PLACEHOLDER
OP_EORI
    Bra DONE    ; PLACEHOLDER
OP_LEA
    Bra DONE    ; PLACEHOLDER
OP_NEG
    Bra DONE    ; PLACEHOLDER
OP_NOT
    Bra DONE    ; PLACEHOLDER
OP_MOVEM_RTOM
    Bra DONE    ; PLACEHOLDER
OP_MOVEM_MTOR
    Bra DONE    ; PLACEHOLDER
OP_RTS
    Bra DONE    ; PLACEHOLDER
OP_JSR
    Bra DONE    ; PLACEHOLDER

;------------------  BRANCH CONDITIONALS  ------------------------;

OP_BRANCH
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'R', (A6)+
        Move.B  #'A', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC
    
OP_BRA_HIGH
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'H', (A6)+
        Move.B  #'I', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC
    
OP_BRA_LOW
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'L', (A6)+
        Move.B  #'S', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC
    
OP_BRA_CC
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'C', (A6)+
        Move.B  #'C', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_CS
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'C', (A6)+
        Move.B  #'S', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_NE
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'N', (A6)+
        Move.B  #'E', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_EQ
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'E', (A6)+
        Move.B  #'Q', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_VC
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'V', (A6)+
        Move.B  #'C', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_VS
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'V', (A6)+
        Move.B  #'S', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_PL
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'P', (A6)+
        Move.B  #'L', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_MI
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'M', (A6)+
        Move.B  #'I', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_GE
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'G', (A6)+
        Move.B  #'E', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_LT
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'L', (A6)+
        Move.B  #'T', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_GT
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'G', (A6)+
        Move.B  #'T', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_BRA_LE
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'L', (A6)+
        Move.B  #'E', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        ;Bra     EA_BCC

OP_MULS
    Bra DONE    ; PLACEHOLDER
OP_AND
    Bra DONE    ; PLACEHOLDER
    
;-----------------  ARITHMETIC SHIFTS  ----------------------;
        
OP_AS_REG
    ; start string
    
        Move.B  #'A', (A6)+
        Move.B  #'S', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
        
    ; Determine data size
    
        Jsr     OP_CHECK_DATA_SIZE
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        ;Bra     EA_AS_REG
        
OP_AS_MEM
    
    ; start string
    
        Move.B  #'A', (A6)+
        Move.B  #'S', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        ;Bra     EA_AS_MEM


;-------------------  LOGICAL SHIFT  ------------------------;

OP_LS_REG
    ; start string
    
        Move.B  #'L', (A6)+
        Move.B  #'S', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
        
    ; Determine data size
    
        Jsr     OP_CHECK_DATA_SIZE
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        ;Bra     EA_LS_REG

    
OP_LS_MEM    

    ; start string
    
        Move.B  #'L', (A6)+
        Move.B  #'S', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        ;Bra     EA_LS_MEM


;----------------------  ROTATE  ----------------------------;

OP_RO_REG
    ; start string
    
        Move.B  #'R', (A6)+
        Move.B  #'O', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
        
    ; Determine data size
    
        Jsr     OP_CHECK_DATA_SIZE
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        ;Bra     EA_RO_REG

    
OP_RO_MEM

    ; start string
    
        Move.B  #'R', (A6)+
        Move.B  #'O', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        ;Bra     EA_RO_MEM


;-----------------------  CMP  ------------------------------;

OP_Cmp
    ; start string
    
        Move.B  #'C', (A6)+
        Move.B  #'M', (A6)+
        Move.B  #'P', (A6)+

    ; Check for address version
        
        Jsr     GET6AND7
        Cmp.B   #%11, D0    ; if both bits are 1 it is an address version
        
        Beq     OP_CMP_ADDR
        
    ; Check which of the two versions is it?

        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff
        ;Bra     EA_CMP
        
OP_CMP_ADDR
        
        Move.B  #'A',(A6)+ ; add to the string
    
    ; Find data size
        
        Jsr     OP_CHECK_DATA_SIZE_ADDR
        
    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff
        ;Bra     EA_CMPA
    

OP_EOR
    Bra DONE    ; PLACEHOLDER

;---------------- Misc Op-Code Sub Routines ----------------;
; Set Bad Buffer
; Sub Routine that sets the Bad buffer bit and returns
;
; REGISTERS USED: D7

OP_SET_BAD_BUFFER
    Move.B  #%1, D7
    Rts

;-------------------------- Tab ----------------------------;
; Sets the total size of the string to be 12 spaces (3 tabs)
; taking into account the current size of the string

; REGISTERS USED: A6, A5(const), D0

OP_TAB
    Move.L      A5,D1   ; Move the start of string to a Dn
    Sub.L       A6,D1   ; Find the compliment of how long the String is
    AddI.B      #12,D1  ; Get the number of spaces before 3 tabs
    
    ; Loop till you have enough spaces
LOOP_TAB
    Move.B      #' ',(A6)+  ; Add a space to the string
    SubI.B      #1,D1       ; Decrement the loop counter (D0)
    BNE         LOOP_TAB    ; Continue looping if the loop counter hasn't hit 0
    
    Rts

;--------------------- Address Version ---------------------;
; This Sub Routine Checks if the Src address is an An and
; Adds an A to the sring if it is, to represent that it is
; Is the Address version of the Op-code. This function assumes
; That D0 will have the mode for the Destination in it.

; REGISTERS USED: D0, D4 (const), D1 (calls Bit Getters)
;                 A6 (Add string input)

OP_CHECK_ADDRESS_VERSION

    Cmp.B    #%001, D0 ; Check to see if the src mode is An
    Beq     OP_ADD_ADDRESS_VERSION ; If true add the 'A'
    
    Rts     ; Otherwise go back without changing anything

OP_ADD_ADDRESS_VERSION
    Move.B  #'A',(A6)+     ; Add the letter A to the string
    
    Rts     ; Finish up and go back
    
;--------------------- Data Size Check ---------------------;
; A set of sub routines to check the size of the data and add it
; To the string.

; REGISTERS USED: D0, D1(Bit Shifts), D4(const), D7(checks illegal ops)
;                 A6(adds letters)    
OP_CHECK_DATA_SIZE
    Jsr     GET6AND7
    
    Cmp.B    #%00, D0    ; Byte Size
    Beq     OP_SET_DATA_BYTE
    
    Cmp.B    #%01, D0    ; Word Size
    Beq     OP_SET_DATA_WORD
    
    Cmp.B    #%10, D0    ; Long Size
    Beq     OP_SET_DATA_LONG
    
    ; If it was not one of those three types, it is not a legal operation
    Bra     OP_SET_BAD_BUFFER     ; Set the Bad buffer bit

OP_CHECK_DATA_SIZE_ADDR
    Jsr     GETBIT8
    
    Cmp.B   #%0, D0     ; Word Size
    Beq     OP_SET_DATA_WORD
                        ; Otherwise its Long Size
    Bra     OP_SET_DATA_LONG

OP_SET_DATA_BYTE

    Move.B  #'.',(A6)+  ; Add Letters
    Move.B  #'B',(A6)+
    
    Rts

OP_SET_DATA_WORD

    Move.B  #'.',(A6)+  ; Add Letters
    Move.B  #'W',(A6)+

    Rts

OP_SET_DATA_LONG

    Move.B  #'.',(A6)+  ; Add Letters
    Move.B  #'L',(A6)+

    Rts

;------------------- Bit Shift Direction -------------------;
; This checks bit 8 to see what direction the shift is going

; REGISTERS USED: D0, D1, D4 (const), A6

OP_SHIFT_DIRECTION
    Jsr     GETBIT8 ; Get the shift direction bit
    
    Cmp.B   #%0,D0  ; 0 is Right
    Beq     OP_SHIFT_RIGHT

    Bra     OP_SHIFT_LEFT   ; Otherwise it's a left shift

OP_SHIFT_RIGHT
    ; Add the character and return
    Move.B  #'R',(A6)+

    Rts    

OP_SHIFT_LEFT
    ; Add the character and return
    Move.B  #'L',(A6)+

    Rts

;---------------- Bit Chopping Sub Routines ----------------;
; These Sub Routines Chop a WORD size piece of data from
; Data register 4 into a smaller piece, leaving just the
; Piece in register 0 while leaving the original piece
; of data intact.

; REGISTERS USED: D0, D1, D4 (const input)

GET12TO15	;1001 0000 0000 0000 -> 1001
			    CLR.L	D0		
				Move.W 	D4, D0		
				
				Move.B	#12, D1		
				LSR.W	    D1, D0		
				
				RTS

GET8TO11	; 0000 1010 0000 0000 -> 1010	
				CLR.L	D0		; Clear out D0
				Move.W 	D4, D0		; Move a copy of the bit string to D0
				
				Move.B	#4, D1		; This is nessassary to move by > 8 bits
				LSL.W 	D1, D0		; Move the string all the way to the left
				
				Move.B	#12, D1		; Change the amount of bits shifted
				LSR.W	    D1, D0		; Move the bits all the way back to the right, isolating the bits
				
				RTS			; Return from the subroutine
				    
GET9TO11	; 0000 1010 0000 0000 -> 101	
				CLR.L	D0		; Clear out D0
				Move.W 	D4, D0		; Move a copy of the bit string to D0
				
				Move.B	#4, D1		; This is nessassary to move by > 8 bits
				LSL.W 	D1, D0		; Move the string all the way to the left
				
				Move.B	#13, D1		; Change the amount of bits shifted
				LSR.W	    D1, D0		; Move the bits all the way back to the right, isolating the bits
				
				RTS			; Return from the subroutine
				
GET6TO8		; 0000 0001 1000 0000 -> 110
				CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#7, D1
				LSL.W 	D1, D0
				
				Move.B	#13, D1
				LSR.W	    D1, D0
				
				RTS
				
GET3TO5		; 0000 0000 0011 1000 -> 111
				CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#10, D1
				LSL.W 	D1, D0
				
				Move.B	#13, D1
				LSR.W	    D1, D0
				
				RTS
GET0TO2		; 0000 0000 0000 0011 -> 011
				CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#13, D1
				LSL.W 	D1, D0
				
				Move.B	#13, D1
				LSR.W	    D1, D0
				
				RTS
GETBIT8		; 0000 0001 0000 0000 -> 1
				CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#7, D1
				LSL.W 	D1, D0
				
				Move.B	#15, D1
				LSR.W	    D1, D0
				
				RTS
				
GET9AND10    ; 0000 0110 0000 0000 -> 11
                CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#5, D1
				LSL.W 	D1, D0
				
				Move.B	#14, D1
				LSR.W	D1, D0
				
				RTS				
				
GET6AND7    ; 0000 0000 1100 0000 -> 11
                CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#8, D1
				LSL.W 	D1, D0
				
				Move.B	#14, D1
				LSR.W	D1, D0
				
				RTS
				
GET3AND4    ; 0000 0000 0001 1000 -> 11
                CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#11, D1
				LSL.W 	D1, D0
				
				Move.B	#14, D1
				LSR.W	D1, D0
				
				RTS

DONE       ; Close out the program
        Move.B #9, D0
        Trap    #15        
        
ILLEGAL     ; PLACEHOLDER
        Bra     DONE
    END    START        ; last line of source











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
