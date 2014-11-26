*-----------------------------------------------------------
* Title      : Test Code
* Written by : Curtis Andersson
* Date       : 11/11/14
* Description: Test Code to help with debugging
*-----------------------------------------------------------
    ORG    $8000
START:                  ; first instruction of program

;-------------- MOVE -----------------;

    Move.B      $4214,D1
    Move.W      -(A5),D2
    Move.W      $8000,D4
    Move.L      #12345678,$7000

    MoveA.W     #$3000,A0
    MoveA.L     D1,A5
    
    ;Add MoveM
    
;-------------- ADD ------------------;

    Add.B       D1,D2
    Add.W       D2,(A1)
    Add.L       (A3)+,D1

    AddA.W      $1234,A4
    AddA.W      $89AB,A4
    AddA.L      $1234,A5

    ;Add ADDI

;-------------- SUB ------------------;

    Sub.B       -(A3),D5
    Sub.W       D7, $12345678
    Sub.L       D4, D6

    SubA.W      (A1),A2
    SubA.L      D1,A4

    ; Add SUBI

;-------------- CMP -------------------;

    Cmp.B       D2,D4
    Cmp.W       (A6),D3
    Cmp.L       #1245,D5
    
    CmpA.W      #$FFFF,A4
    CmpA.L      (A4)+,A5
    
    ; Add CMPI

;------------ BCC & Jumps --------------;

    Bra         $1234
    Beq         $5678
    
    Jsr         $ABCD
    Rts
    
;--------- SHIFT FUNCTIONS -------------;

    ASL.B       D1, D2
    ASR.L       #5, D4
    ASR         (A3)
    
    LSL.L       D2,D3
    LSR.B       #1,D4
    LSL         $8000
    
    ROR.L       D1,D5
    ROL.B       #6,D2
    
;--------- IMMEDIATE FUNCTIONS ---------;

    CmpI.W  #$ABCD, D4
    CmpI.L  #$87654321, $12345678
    
    OrI.B   #$02,(A6)
    OrI.L   #12,(A5)+
    
    SubI.W  #1423,-(A3)
    SubI.B  #12,D3
    
    EorI.L  #$ABCE1452,(A5)
    EorI.B  #255,$FFFFA000
        
;------- Neg - Not - Muls - Divs -------;

    Neg.L   D1
    Neg.W   (A3)
    Neg.B   (A6)+
    
    Not.L   -(A2)
    Not.B   D3
    Not.W   $7532
    
    Muls.W  $9764, D4
    Muls.W  #15, D6
    
    Divs.W  #3,D7
    Divs.W  (A2),D3


* Put variables and constants here

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
