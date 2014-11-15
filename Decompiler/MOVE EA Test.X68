*-----------------------------------------------------------
* Title      : Move EA Test
* Written by : John Louie
* Date       : 11-11-14
* Description: Testing Move EA
*-----------------------------------------------------------
;----- Variables to identify modes/registers -----;
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

;----- Test variables -----;
Test_Move1          EQU     %0001010000000001   ; Move.B D1,D2
Test_Move2          EQU     %0001010001000100   ; Move.B A2,D4 INCORRECT
Test_Move3          EQU     %0001111010010000   ; Move.B (A0),(A7) 
    
    ORG    $1000
    
START:                  ; first instruction of program
        ;Move.W  #Test_Move1, D4
        ;Move.W  #Test_Move2, D4
        Move.W  #Test_Move3, D4
        
        Bra     EA_Move     ; Branch to EA function for Move
        
;----- Effective Address Sub Routines -----;
; These subroutines look for the correct effective address
; in each OP code.

;----- EA Move -----;
EA_Move
        Jsr     EA_Move_Source          ; Add the EA for source
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_Move_Dest            ; Add the EA for destination
                
EA_Move_Source  ; Find out Move's source
        Jsr     GET3TO5                 ; Get source mode
        Move.B  D0, D5                  ; Move source mode to D5
        Jsr     Get0TO2                 ; Get source register
        
        ; List of valid effective addresses
        Cmp.B   #Dn_Mode, D5            ; Dn
        Beq     EA_Dn
        
        Cmp.B   #An_Mode, D5            ; An
        Beq     EA_An
        
        Cmp.B   #An_Pntr_Mode, D5       ; (An)
        Beq     EA_An_Pntr
        
        Rts
        
EA_Move_Dest    ; Find out Move's destination
        Jsr     GET6TO8                 ; Get destination mode
        Move.B  D0, D5                  ; Move destination mode to D5
        Jsr     Get9TO11                ; Get destination register
        
        ; List of valid effective addresses
        Cmp.B   #Dn_Mode, D5            ; Dn
        Beq     EA_Dn
        
        Cmp.B   #An_Pntr_Mode, D5       ; (An)
        Beq     EA_An_Pntr
        
        Rts
        
;----- General EA functions -----;
EA_Dn   ; Adds Dn EA to string
        Move.B  #'D', (A6)+             
        Add.B   #$30, D0        
        Move.B  D0, (A6)+               
                
        Rts

EA_An   ; Adds An EA to string
        Move.B  #'A', (A6)+
        Add.B   #$30, D0    
        Move.B  D0, (A6)+               
                
        Rts

EA_An_Pntr  ; Adds (An) EA to string
        Move.B  #'(', (A6)+
        Move.B  #'A', (A6)+
        Add.B   #$30, D0
        Move.B  D0, (A6)+
        Move.B  #')', (A6)+
                
        Rts

EA_Imm_Word
        ; Once you know that the data size for the op-code is size Word or Byte
        
        ; grab a word of data from (A3)+ (Move.W (A3)+, Dn)
        ; put in the char '#' and '$'
        ; convert data to ASCII in some way (maybe)
        
EA_Imm_Long

EA_Word_Addr
        ; Get one word of data
        ; use sign extension to fill out the remaining 32 bits
        ; If word is < $8000, add '0' 4 times
        ; If word is >= $8000, add 'F' 4 times
        
        ; Add a '$'
        ; convert the data to ASCII
EA_Long_Addr
        ; Get two words of data
        
        ; Add a '$'
        ; convert the data to ASCII
;---------------- Bit Chopping Sub Routines ----------------;
; These Sub Routines Chop a WORD size piece of data from
; Data register 4 into a smaller piece, leaving just the
; Piece in register 0 while leaving the original piece
; of data intact.

GET12TO15
		CLR.L	D0
		Move.W 	D4, D0
				
		Move.B	#12, D1
		LSR	    D1, D0
				
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
