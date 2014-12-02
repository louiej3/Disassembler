*-----------------------------------------------------------
* Title      : Disassembler - I/O Part
* Written by : Blong Thao
* Date       : 11/16/14
* Description: This program asks for the starting address
*               and the ending address, then reads the data
*               in the specified range and disassembles the
*               data in the memory to instructions.               
*-----------------------------------------------------------
CR              EQU     $0D                 ; Carriage return
LF              EQU     $0A                 ; Line Feed
HT              EQU     $09                 ; Tab (horizontal 5 characters)
begin           EQU     $00000000           ; Lowest starting address
end             EQU     $00FFFFFE           ; Highest ending address
Dn_Mode         EQU     %000
An_Mode         EQU     %001
An_Pntr_Mode    EQU     %010
An_Inc_Mode     EQU     %011
An_Dec_Mode     EQU     %100
Word_Mode       EQU     %111
Word_Reg        EQU     %000
Long_Mode       EQU     %111
Long_Reg        EQU     %001
Imm_Mode        EQU     %111
Imm_Reg         EQU     %100

                ORG     $1000
START       
*-----------Introduction Message----------------------------
                LEA     intro_stuff, A1     ; Load introduction
                MOVE.B  #14, D0             ; Load task code for display
                TRAP    #15                 ; Display introduction
                LEA     intro_msg, A1       ; Load introduction
                MOVE.B  #14, D0             ; Load task code for display
                TRAP    #15                 ; Display introduction
                LEA     intro_stuff, A1     ; Load introduction
                MOVE.B  #13, D0             ; Load task code for display
                TRAP    #15                 ; Display introduction
                

*-----------Prompt For Starting Address---------------------                  
prompt_start    LEA     start_address,A1    ; Load prompt message for starting address
                MOVE.B  #14,D0              ; Load task code for display
                TRAP    #15                 ; Display prompt message
                
                LEA     start_input,A1      ; Load address to store user's input
                MOVE.B  #2,D0               ; Load task code for user input
                TRAP    #15                 ; Ask for user input
                JSR     verify_input        ; Verifies user input string
                CMP.B   #1,D4               ; If equal to 1, then that input is valid
                BEQ     valid_start         ; Go to valid start if equal 
                
                LEA     badAddr_input,A1        ; Not equal to 1, its a bad input, start over
                MOVE.B  #14,D0              ; Load task code for display
                TRAP    #15                 ; Display bad input message
                BRA     prompt_start        ; Go back beginning, asking for start address

valid_start     JSR     chk_bound           ; Check if the input has odd/even bounds
                CMP.W   #-1,D3              ; If -1 in D3, then input was odd
                BEQ     prompt_start        ; Go back and ask for correct input
                MOVE.L  #begin,D6           ; Store minimum address in D6
                CMP.L   D6,D3               ; If start address is lower than minimum address
                BLT     start_error         ; Then, start address is too low
                MOVE.L  #end,D6             ; Store max end address for comparison
                CMP.L   D6,D3               ; If start address is lower than minimum address
                BGT     start_error         ; Then, start address is too high
                MOVEA.L D3,A3               ; Load starting address                 

*-----------Prompt for Ending Address-----------------------            
prompt_end      LEA     end_address1,A1     ; Load prompt msg for ending address(1/2)
                MOVE.B  #14,D0              ; Load task code for display
                TRAP    #15                 ; Display prompt message
                LEA     start_input,A1      ; Load starting address
                TRAP    #15                 ; Display starting address
                LEA     end_address2,A1     ; Load prompt msg for ending address(2/2)
                TRAP    #15                 ; Display prompt message
                LEA     end_input,A1        ; Ask for ending address
                MOVE.B  #2,D0               ; Load task code for input
                TRAP    #15                 ; Prompt for input
                JSR     verify_input        ; Verifies user input string
                CMP.B   #1,D4               ; If 1 in D4, then its valid
                BEQ     valid_end           ; Now validate the ending address
                LEA     badAddr_input,A1        ; Else, bad input
                MOVE.B  #14,D0              ; Load task code for display
                TRAP    #15                 ; Display bad input message
                BRA     prompt_end          ; Restart process

valid_end       JSR     chk_bound           ; Check if the input has odd/even bounds
                CMP.W   #-1,D3              ; If -1(FFFF), then it has odd bounds
                BEQ     prompt_end          ; Go back and ask for correct input
                MOVE.L  #end,D6             ; Move max address to compare with input
                CMP.L   D6,D3               ; Is input higher than max
                BGT     end_error           ; Input address is too high
                CMP.L   A3,D3               ; Is input at or above minimum address
                BLT     end_error           ; Input address is too low
                MOVEA.L D3,A4               ; Load ending address
                               
;-------------- disassemble ---------------------------------------------------
; -- Reads the data from the specified memory locations
; -- Passes the data over to OP-code to verify the instruction
; -- Decodes the word data from the specified memory location until the end
; -- Checks for illegal data and valid data with the bad buffer bit
;------------------------------------------------------------------------------
disassemble     CLR.L   D3                  ; Clear for IO usage
                CLR.L   D4                  ; Clear for OP Code usage              
                CMP.L   A4,A3               ; At the end address?
                BGT     prompt_to_rerun     ; Placeholder for printing out the instructions
                
                JSR     check_10_lines      ; Prompt user to see more at 10 lines of data
                MOVE.L  A3,D6               ; Store current address
                
                LEA     illegal_data,A6     ; Load illegal data's address
                JSR     hex_to_ASCII_L      ; Store address to memory for display
                MOVEA.L A6,A0               ; Store current location of illegal data
                
                LEA     valid_data,A5       ; Store current address to memory
                
                LEA     valid_data,A6       ; Store current address to memory
                JSR     hex_to_ASCII_L      ; Store current address to memory as string
                MOVE.B  #HT,(A6)+           ; Store a TAB
                
                MOVE.W  (A3)+,D4            ; Read data from current memory location                
                JSR     OP_CODE_TREE        ; Go to OP code jump table
                
                CMP.B   #1,D7               ; Bad buffer set?
                BEQ     ILLEGAL             ; Yes, go to ILLEGAL function                
main_loop
                ; Store new line in memory
                MOVE.B  #LF,(A6)+
                MOVE.B  #CR,(A6)+
                CMP.B   #1,D7               ; Bad buffer set?
                BNE     good_buff           ; Good Buffer, go prep for display
                
bad_buff        CLR.L   D7                  ; Reset bad buffer
                MOVE.B  #00,(A6)+           ; Add null terminator
                LEA     illegal_data,A1     ; Load the illegal data for display
                BRA     display_data        ; Go to display data
                
good_buff       MOVE.B  #00,(A6)+           ; Add null terminator
                LEA     valid_data,A1       ; Load the valid data for display
                
display_data    CLR.L   D0                  ; Clear for TASK TRAP
                MOVE.B  #14,D0              ; Display the data that A1 is pointing
                TRAP    #15                 ; to in memory.
                BRA     disassemble         ; Done disassembling the word, next word                
                                               
ILLEGAL         ; word data from memory is not a required instruction
                LEA     illegal_data,A5     ; Store current address to memory
                MOVEA.L A0,A6               ; Use A6 to write illegal data                
                MOVE.B  #HT,(A6)+           ; Store TAB 
                MOVE.B  #'D',(A6)+          ; Store DATA
                MOVE.B  #'A',(A6)+
                MOVE.B  #'T',(A6)+
                MOVE.B  #'A',(A6)+
                JSR     OP_TAB              ; Set up third collumn
                MOVE.B  #'$',(A6)+
                
                ; Store 4 hex digits that represent the word into memory
                CLR.L   D6
                MOVE.W  D4,D6               ; Move the word data into D6 for conversion
                JSR     hex_to_ASCII_W      ; Converts hex to ascii for the word data
                BRA     main_loop           ; Store info to memory as string              

;------------check_10_lines----------------------------------------------------
; -- Prompt user to hit enter when there are 10 lines of data
; -- Then reset the line count and go back to disassemble more data
;------------------------------------------------------------------------------
check_10_lines
                LEA     line_count,A2       ; Assign A2 pointer for line count
                ADD.B   #1,(A2)             ; Increment counter
                CMP.B   #20,(A2)            ; Has counter reached 31 yet?
                BEQ     prompt_for_data     ; At 31
                RTS                         ; Return to disassemble

prompt_for_data LEA     hit_enter_msg,A1    ; Ask user to hit enter
                MOVE.B  #14,D0              ; Display message
                TRAP    #15
                LEA     hit_enter,A1        ; Take user input
                MOVE.B  #2,D0               
                TRAP    #15
                MOVE.B  #0,(A2)             ; Reset counter
                RTS                         ; Return to disassemble

;------------prompt_to_rerun----------------------------------------------------
; -- Prompt user to rerun or end program
;------------------------------------------------------------------------------
prompt_to_rerun LEA     ask_user,A1         ; Load ask user message to rerun 
                MOVE.B  #14,D0
                TRAP    #15
                LEA     ask_input,A1        ; Take user input
                MOVE.B  #2,D0
                TRAP    #15
                LEA     line_count,A2       ; Load line count to reset
                MOVE.B  #0,(A2)             ; Reset the line_count
                CMP.B   #1,D1               ; User input must be the length of 1
                BGT     rerun_err_msg       ; Otherwise, will prompt msg again
                BLT     rerun_err_msg       ; until the user inputs correctly.
                CLR     D0                  ; Clear D0 for comparison
                MOVE.B  ask_input,D0        ; Load user input for comparison
                CMP.B   #'N',D0             ; User input is N
                BEQ     done                ; End of program if N
                CMP.B   #'n',D0             ; User input is n
                BEQ     done                ; End of program if n
                CMP.B   #'Y',D0             ; User input is Y
                BEQ     prompt_start        ; Run the program again
                CMP.B   #'y',D0             ; User input is y
                BEQ     prompt_start        ; Run the program again
                BRA     rerun_err_msg       ; Bad input, prompt user
                
rerun_err_msg   LEA     ask_error,A1        ; Bad input, display error message
                MOVE.B  #14,D0
                TRAP    #15
                BRA     prompt_to_rerun     ; Prompt user for rerun           
                
    
;------------End-of-Program----------------------------------------------------                
done            LEA     ending,A1           ; Load ending message
                MOVE.B  #13,D0              ; Load task code for display
                TRAP    #15                 ; Display ending message
                STOP    #$00002700          ; End of program
                
;-----------Verify/ConvertASCIItoHex-------------------------------------------
verify_input    CLR.L   D3                  ; D3 will hold valid user input chars
                CLR.L   D5                  ; D5 will be used as a NULL comparison
                CMP.B   D5,D1               ; Check input length, if lower than one
                BEQ     invalid             ; Its an invalid input
                CMPI    #$8,D1              ; Check input length, if higher than 8
                BGT     invalid             ; Its an invalid input
                
check_input     CLR.L   D2                  ; Clear D2 to store chars from user input
                MOVE.B  (A1)+,D2            ; Move next char to D2 to validate
                CMP.B   D5,D2               ; Check to see if next char is null(0)
                BEQ     return              ; Character is null, end of input
                
                CMP.B   #70,D2              ; Invalid character if decimal value
                BGT     invalid             ; is higher than 70.
                CMP.B   #64,D2              ; Is a letter if decimal value is 
                BGT     is_letter           ; between 65 - 70.
                
                CMP.B   #57,D2              ; Invalid character if decimal value is
                BGT     invalid             ; between 58 - 64
                CMP.B   #47,D2              ; Is a number if decimal value is 
                BGT     is_number           ; between 48 - 57.
                BRA     invalid             ; Decimal values below 48 are invalid 
                             
is_number       SUBI.B  #48,D2              ; Convert ASCII to Hex, 0-9
                BRA     verified            ; Put character into a register
                             
is_letter       SUBI.B  #55,D2              ; Convert ASCII to HEX, A-F
                BRA     verified            ; Put character into a register
               
verified        ASL.L   #4,D3               ; Shift hex bit left one
                ADD.B   D2,D3               ; Add to verified register
                BRA     check_input         ; Check the rest of the input                       
                
invalid         MOVEQ   #0,D4               ; Invalid address
                RTS                         ; Return to start/end prompt
                
return          MOVEQ   #1,D4               ; Valid address
                RTS                         ; Return to start/end prompt
                
;----------------------------------------------------------
; Convert Hexidecimal to ASCII (Stores into Memory)
;
; -- At the moment, takes the Illegal data and stores 
;    it into memory so that it can be printed later
;----------------------------------------------------------
hex_to_ASCII_L  CLR.L   D1                      ; Used for shifting right
                CLR.L   D2                      ; Used for shifting left
                CLR.L   D3                      ; Counter
                MOVE.B  #28,D1                  ; Shift right by 7 hex digits                  
hex_ASCII_loopL
                CMP.B   #8,D3                   ; Done converting?
                BEQ     done_converting         ; If equal to 8, done
                MOVE.L  D6,D0                   ; Do calculations in D0
                LSL.L   D2,D0                   ; Eliminate stuff to the left
                LSR.L   D1,D0                   ; Isolate number
                JSR     convert_hex
                BRA     hex_ASCII_loopL
                
hex_to_ASCII_W  CLR.L   D1                      ; Used for shifting right
                CLR.L   D2                      ; Used for shifting left
                CLR.L   D3                      ; Counter
                MOVE.B  #12,D1                  ; Shift right by 3 hex digits                  
hex_ASCII_loopW
                CMP.B   #4,D3                   ; Done converting?
                BEQ     done_converting         ; If equal to 4, done
                MOVE.L  D6,D0                   ; Do calculations in D0
                LSL.W   D2,D0                   ; Eliminate stuff to the left
                LSR.W   D1,D0                   ; Isolate number
                JSR     convert_hex
                BRA     hex_ASCII_loopW

hex_to_ASCII_B  CLR.L   D1                      ; Used for shifting right
                CLR.L   D2                      ; Used for shifting left
                CLR.L   D3                      ; Counter
                MOVE.B  #4,D1                   ; Shift right by 1 hex digits                  
hex_ASCII_loopB
                CMP.B   #2,D3                   ; Done converting?
                BEQ     done_converting         ; If equal to 2, done
                MOVE.L  D6,D0                   ; Do calculations in D0
                LSL.B   D2,D0                   ; Eliminate stuff to the left
                LSR.B   D1,D0                   ; Isolate number
                JSR     convert_hex
                BRA     hex_ASCII_loopB                  

convert_hex     CMP.B   #$A,D0                  ; What should I make this hex digit?
                BLT     make_number             ; Make it a number, if lower than 10
                BGE     make_letter             ; Make it a letter, if greater than or eqaul to 10
                     
make_number     ADD.B   #48,D0                  ; Convert to Ascii (0-9)
                MOVE.B  D0,(A6)+                ; Store in memory
                ADD.B   #1,D3                   ; Add to counter
                ADD.B   #4,D2                   ; Shift left by one digit
                RTS                             ; Check next number
                
make_letter     ADD.B   #55,D0                  ; Convert to Ascii (0-9)
                MOVE.B  D0,(A6)+                ; Store to memory
                ADD.B   #1,D3                   ; Add to counter
                ADD.B   #4,D2                   ; Shift left by one digit                 
done_converting RTS                             ; Check next number              

;-----------Error Messages ----------------------------------------------------
start_error     JSR     load_bad_input      ; Print bad input error message
                JMP     prompt_start        ; Return to prompt for start address
                
end_error       JSR     load_bad_input      ; Print bad input error message
                JMP     prompt_end          ; Return to prompt for end address

load_bad_input  LEA     badAddr_input,A1    ; Load bad input message
                MOVE.B  #13,D0              ; Load task code for display
                TRAP    #15                 ; Display bad input message
                RTS                         ; Return to (start/end)_error

chk_bound       CLR.L   D2                  ; Clear buffer before usage
                MOVE.W  D3,D2               ; Put address in D2 for calulation
                MOVE.L  #2,D1               ; Load 2 into D1 for division
                DIVU    D1,D2               ; Divide address by 2
                SWAP    D2                  ; Swap contents of D2 to get remainder
                CMP.B   #$01,D2             ; Check remainder, if one then address is odd
                BEQ     odd_err             ; Go to print out odd bound error message
                RTS                         ; Return to valid_(start/end)
                
odd_err         LEA     odd_input,A1        ; Load odd input message
                MOVE.B  #14,D0              ; Load task code for display
                TRAP    #15                 ; Display odd input message
                NOT.L   D5                  ; Change D5 to -1(FFFF) to return as bad address
                MOVE.L  D5,D3               ; Load -1 to returned data register
                RTS                         ; Return to valid_(start/end)

OP_CODE_TREE    ; Parses the Op-Code to find what it is
        
        Cmp.L   #$4E75, D4         ; Check for RTS (non-variable op-codes)
        Beq     OP_RTS

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
        
        Bra     OP_SET_BAD_BUFFER         ; If the first 4 has not been covered, then the code is illegal
        
IMMEDIATE_BTST  ; Continue through Op-code Tree, first 4 are 0000
        
        Jsr     GET6TO8         ; Change out test bits
        
        Cmp.B     #%100, D0          ; Bit test
        Beq     OP_BTST
        
        Jsr     GET6TO11
        
        Cmp.B   #%100000,D0     ;BTST
        Beq     OP_BTST
        
        Jsr     GET9TO11        ; Change out test bits
        
        Cmp.B     #%000, D0        ; Or I
        Beq     OP_ORI
        
        Cmp.B     #%010, D0        ; Subtract I
        Beq     OP_SUBI
        
        Cmp.B     #%101, D0        ; Exclusive or, I
        Beq     OP_EORI
        
        Cmp.B     #%110, D0        ; Compare I
        Beq     OP_CMPI
        
        Bra     OP_SET_BAD_BUFFER         ; Everything else is uncovered
        
SINGLE_OPERATOR_CODES   ; Continue through Op-code Tree, first 4 are 0100

        Jsr     GETBIT8        ; Change out test bits
        
        Cmp.B     #%1, D0      ; Load effetive address
        Beq     OP_LEA
        
        Jsr     GET9TO11       ; Change out test bits        

        Cmp.B     #%010, D0    ; Negate
        Beq     OP_NEG
       
        Cmp.B     #%011, D0    ; Not
        Beq     OP_NOT
        
        Cmp.B     #%100, D0    ; Move multiple registers Registers -> Memory
        Beq     OP_MOVEM
        
        Cmp.B     #%110, D0    ; Move multiple registers Memory -> Registers
        Beq     OP_MOVEM
        
        Bra     OP_SET_BAD_BUFFER     ; Everything else is uncovered

JSR_RTS     ; Continue through OP tree, first 4 are 0100, 8-11 are 1110

        Jsr     GET6TO8        ; Change out test bits        

        Cmp.B     #%001, D0    ; Return from subroutine
        Beq     OP_RTS
        
        Cmp.B     #%010, D0    ; Jump to Subroutine
        Beq     OP_JSR
        
        Bra     OP_SET_BAD_BUFFER     ; Everything else is uncovered

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
        
        Bra     OP_SET_BAD_BUFFER     ; Not including False* because it makes no sense

AND_MULS        ; Continue through the Op-code Tree, The first four bits are 1100

        Jsr     Get3TO8
        
        Cmp.B     #%100001, D0   ; ABCD
        Beq     OP_SET_BAD_BUFFER        
        Cmp.B     #%100000,D0    ; ABCD
        Beq     OP_SET_BAD_BUFFER        
        Cmp.B     #%101000,D0    ; EXG
        Beq     OP_SET_BAD_BUFFER
        Cmp.B     #%101001,D0    ; EXG
        Beq     OP_SET_BAD_BUFFER
        Cmp.B     #%110001,D0    ; EXG
        Beq     ILLEGAL        

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
        
        Bra     OP_SET_BAD_BUFFER         ; Otherwise it is not an accepted command

BIT_SHIFT_REG
        
        Jsr     GET3AND4        ; Change out test bits
        
        Cmp.B     #%00, D0        ; Arithmetic Shifts (Left or Right)
        Beq     OP_AS_REG
        
        Cmp.B     #%01, D0        ; Logical Shift (Left or Right)
        Beq     OP_LS_REG
        
        Cmp.B     #%11, D0        ; Rotate (Left or Right)
        Beq     OP_RO_REG
        
        Bra     OP_SET_BAD_BUFFER         ; Otherwise it is not an accepted command
CMP_EOR     ; Continue through the Op-code Tree, The first four bits are 1011     
        
        Jsr     GET6TO8         ; Change out test bits
        
        Cmp.B     #%100, D0         ; If bit 8 is 1, It much be EOR
        Beq     OP_EOR
        
        Cmp.B     #%101,D0
        Beq     OP_EOR
        
        Cmp.B     #%110,D0
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
        BRA     EA_MOVE        

OP_MOVE_DATA
        
        Cmp     #%0001, D0
        Beq     OP_SET_DATA_BYTE
        
        Cmp     #%0010, D0
        Beq     OP_SET_DATA_LONG
        
        Cmp     #%0011, D0
        Beq     OP_SET_DATA_WORD
        
        Rts

;-----------------------  ADDQ  -----------------------------;
        
OP_ADDQ
    ; Check fringe cases
        Jsr     GETBIT8
        Cmp.B   #%1,D0
        Beq     OP_SET_BAD_BUFFER        
        Jsr     GET6AND7
        Cmp.B   #%11,D0
        Beq     OP_SET_BAD_BUFFER       ; Blong edited, was Bne

    ; start string
    
        Move.B  #'A', (A6)+
        Move.B  #'D', (A6)+
        Move.B  #'D', (A6)+
        Move.B  #'Q', (A6)+
        
    ; Check data type        
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John / Blong edited, was EA_IMMEDIATE
        BRA     EA_ADDQ

    
;------------------  DIVIDE SINGED  -------------------------;
    
OP_DIVS
    ; One last check to make sure I have the right stuff
    
        Jsr     GET6TO8
        Cmp     #%111,D0
        Bne     OP_SET_BAD_BUFFER
        
    ; start string
    
        Move.B  #'D', (A6)+
        Move.B  #'I', (A6)+
        Move.B  #'V', (A6)+
        Move.B  #'S', (A6)+
        Move.B  #'.', (A6)+
        Move.B  #'W', (A6)+
        
    ; Put in tabs
        Jsr     OP_TAB    
    
    ; Handoff to John
        
        BRA     EA_DIVS

    
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
        
        BRA     EA_SUB 
        
OP_SUB_ADDR
        
        Move.B  #'A',(A6)+ ; add to the string
        
        ; Find data size
        
        Jsr     OP_CHECK_DATA_SIZE_ADDR
        
        ; Put in tabs
        Jsr     OP_TAB
        
        ; Handoff
        BRA     EA_SUB
        
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
        
        BRA     EA_ADD
        
OP_ADD_ADDR
        
        Move.B  #'A',(A6)+ ; add to the string
        
        ; Find data size
        
        Jsr     OP_CHECK_DATA_SIZE_ADDR
        
        ; Put in tabs
        Jsr     OP_TAB
        
        ; Handoff
        BRA     EA_ADDA

;------------------------  BTST -----------------------------;

OP_BTST
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'T', (A6)+
        Move.B  #'S', (A6)+
        Move.B  #'T', (A6)+
        
    ; Btst has data sizes, but they are implicit based on mode
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_BTST


;---------------  IMEMDIATE FUNCTIONS  ----------------------;

;------------------------  ORI  -----------------------------;
    
OP_ORI
    ; start string
    
        Move.B  #'O', (A6)+
        Move.B  #'R', (A6)+
        Move.B  #'I', (A6)+
        
    ; Check data type        
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_IMMEDIATE

;-----------------------  SUBI  -----------------------------;

OP_SUBI
    ; start string
    
        Move.B  #'S', (A6)+
        Move.B  #'U', (A6)+
        Move.B  #'B', (A6)+
        Move.B  #'I', (A6)+
        
    ; Check data type        
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_IMMEDIATE  
        
;-----------------------  EORI  -----------------------------;        
        
OP_EORI
    ; start string
    
        Move.B  #'E', (A6)+
        Move.B  #'O', (A6)+
        Move.B  #'R', (A6)+
        Move.B  #'I', (A6)+
        
    ; Check data type        
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_IMMEDIATE  
        
;-----------------------  CMPI  -----------------------------;        
        
OP_CMPI
    ; start string
    
        Move.B  #'C', (A6)+
        Move.B  #'M', (A6)+
        Move.B  #'P', (A6)+
        Move.B  #'I', (A6)+
        
    ; Check data type        
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_IMMEDIATE  
        
;-----------------------  LEA  ------------------------------;

OP_LEA
    ; start string
    
        Move.B  #'L', (A6)+
        Move.B  #'E', (A6)+
        Move.B  #'A', (A6)+
        
    ; No data size for LEA
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_LEA  

;-----------------------  NEG  ------------------------------;

OP_NEG
    ; start string
    
        Move.B  #'N', (A6)+
        Move.B  #'E', (A6)+
        Move.B  #'G', (A6)+
        
    ; Data size
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_NEG  

    
;-----------------------  NOT  ------------------------------;    
    
OP_NOT
    ; start string
    
        Move.B  #'N', (A6)+
        Move.B  #'O', (A6)+
        Move.B  #'T', (A6)+
        
    ; Data size
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_NOT

;-------------------  MOVE MULITPLE  ------------------------;
        
OP_MOVEM
    ; Exception checks
        Jsr     GET7AND8
        Cmp.B   #%01,D0
        Bne     SET_BAD_BUFFER_BIT
        
        Jsr     GET3TO5
        Cmp.B   #%000,D0
        Bne     SET_BAD_BUFFER_BIT

    ; start string
    
        Move.B  #'M', (A6)+
        Move.B  #'O', (A6)+
        Move.B  #'V', (A6)+
        Move.B  #'E', (A6)+
        Move.B  #'M', (A6)+        

    ; Data size has to be checked manually
        Jsr     OP_MOVEM_DATA
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_MOVEM
        
OP_MOVEM_DATA
    ; get the size bit
        Jsr     GET6AND7
        
        Cmp.B   #%10,D0
        Beq     OP_SET_DATA_WORD
        
        Bra     OP_SET_DATA_LONG   

OP_RTS
    ; start string
    
        Move.B  #'R', (A6)+
        Move.B  #'T', (A6)+
        Move.B  #'S', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to Blong
    
        Rts
        
;-----------------------  JSR  ------------------------------;        
        
OP_JSR
    ; start string
    
        Move.B  #'J', (A6)+
        Move.B  #'S', (A6)+
        Move.B  #'R', (A6)+
        
    ; No data size
        
    ; Put in tabs
        Jsr     OP_TAB
        
    ; Hand the function off to John
        BRA     EA_JSR

;------------------  BRANCH CONDITIONALS  ------------------------;

OP_BRANCH
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'R', (A6)+
        Move.B  #'A', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH
    
OP_BRA_HIGH
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'H', (A6)+
        Move.B  #'I', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH
    
OP_BRA_LOW
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'L', (A6)+
        Move.B  #'S', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH
    
OP_BRA_CC
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'C', (A6)+
        Move.B  #'C', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_CS
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'C', (A6)+
        Move.B  #'S', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_NE
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'N', (A6)+
        Move.B  #'E', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_EQ
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'E', (A6)+
        Move.B  #'Q', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_VC
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'V', (A6)+
        Move.B  #'C', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_VS
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'V', (A6)+
        Move.B  #'S', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_PL
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'P', (A6)+
        Move.B  #'L', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_MI
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'M', (A6)+
        Move.B  #'I', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_GE
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'G', (A6)+
        Move.B  #'E', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_LT
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'L', (A6)+
        Move.B  #'T', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_GT
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'G', (A6)+
        Move.B  #'T', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

OP_BRA_LE
    ; start string
    
        Move.B  #'B', (A6)+
        Move.B  #'L', (A6)+
        Move.B  #'E', (A6)+

    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff to John
    
        BRA     EA_BRANCH

;------------------  Multiply Singed ----------------------;    

OP_MULS
    ; MULS only has one format, and that data size of word, so I don't need
    ; a very intelligent system
    
        Move.B  #'M', (A6)+
        Move.B  #'U', (A6)+
        Move.B  #'L', (A6)+
        Move.B  #'S', (A6)+
        Move.B  #'.', (A6)+
        Move.B  #'W', (A6)+

    ; Put in tabs
        Jsr     OP_TAB       
    
    ; Give to john
    
        BRA     EA_MULS

    
;-----------------------  AND  ------------------------------;    
    
OP_AND
    ; start string
    
        Move.B  #'A', (A6)+
        Move.B  #'N', (A6)+
        Move.B  #'D', (A6)+

    ; No Address Version
        
    ; Check data size
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    BRA     EA_AND

    
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
        BRA     EA_BIT_SHIFT
        
OP_AS_MEM
    
    ; start string
    
        Move.B  #'A', (A6)+
        Move.B  #'S', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        BRA     EA_BIT_SHIFT


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
        BRA     EA_BIT_SHIFT

    
OP_LS_MEM    

    ; start string
    
        Move.B  #'L', (A6)+
        Move.B  #'S', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        BRA     EA_BIT_SHIFT


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
        BRA     EA_BIT_SHIFT

    
OP_RO_MEM

    ; start string
    
        Move.B  #'R', (A6)+
        Move.B  #'O', (A6)+
        
    ; Determine Left or right shift
    
        Jsr     OP_SHIFT_DIRECTION  ;Check the shift direction
       
    ; Tab out function
    
        Jsr     OP_TAB
       
    ; Handoff function
        BRA     EA_BIT_SHIFT


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
        BRA     EA_CMP
        
OP_CMP_ADDR
        
        Move.B  #'A',(A6)+ ; add to the string
    
    ; Find data size
        
        Jsr     OP_CHECK_DATA_SIZE_ADDR
        
    ; Put in tabs
        Jsr     OP_TAB

    ; Handoff
        BRA     EA_CMP
    
;-----------------------  EOR  ------------------------------;

OP_EOR
    ; start string
    
        Move.B  #'E', (A6)+
        Move.B  #'O', (A6)+
        Move.B  #'R', (A6)+

    ; No Address Version
        
    ; Check data size
        Jsr     OP_CHECK_DATA_SIZE
        
    ; Put in tabs
        Jsr     OP_TAB
        
    BRA     EA_EOR

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
    AddI.L      #20,D1  ; Get the number of spaces before 3 tabs
    
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
        
        RTS
                
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
        
;=================================================================;
;---------------------------- EA MoveM ---------------------------;
; D2 stores the counter for the number of consecutive ones in the
; register list mask
;
; D3 stores a 1 if the register being added is the first register, 
; or 0 if the register is not the first register being added
;
; D5 stores the register list mask
;
; D6 stores any expansion words
;
; D7 stores the loop counter
;=================================================================;
EA_MOVEM    ; Determines the EA for MoveM
        MoveM.L D2-D7, -(SP)            ; Save D2-D7 at address A4 so we can use them for MoveM 
        
        Clr.L   D2                      ; Clear out the data registers
        Clr.L   D3
        Clr.L   D5
        Clr.L   D6
        Clr.L   D7
        
        Add.B   #1, D3                  ; Set D3 to 1 to specify the first register
        Move.W  (A3)+, D5               ; Store the register list mask
        
        Jsr     GETBIT10                ; Get the direction bit
        
        Cmp.B   #%0, D0                 ; If direction bit is 0, register to memory
        Beq     EA_MOVEM_REG_TO_MEM
        
        Jmp     EA_MOVEM_MEM_TO_REG     ; Else, memory to register
        
EA_MOVEM_REG_TO_MEM ; Determines EA for register to memory transfer direction
        Jsr     EA_MOVEM_LIST_LOOP      ; Get the list of registers
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_0TO5                 ; Get the EA
        
        MoveM.L (SP)+, D2-D7            ; Restore the saved data registers
                
        RTS
        
EA_MOVEM_MEM_TO_REG ; Determines EA for memory to register transfer direction 
        Move.W  D5, D7                  ; Store the register list mask in D7 temporarily
        Jsr     EA_0TO5                 ; Get the EA
        Move.B  #',', (A6)+             ; Add a comma
        Move.W  D7, D5                  ; Move the register list mask back to D5
        Clr.L   D7                      ; Clear D7
        Jsr     EA_MOVEM_LIST_LOOP      ; Get the list of registers
        
        MoveM.L (SP)+, D2-D7            ; Restore the saved data registers
                
        RTS
                
EA_MOVEM_LIST_LOOP ; Determines if the list is in predecrement order or post increment order
        Cmp.B   #16, D7                 ; If the loop counter is greater than or equal to 16, end
        Bge     EA_MOVEM_LIST_END

        Jsr     GET3TO5                 ; Get the EA mode
        
        Cmp.B   #%100, D0               ; Predecrement mode
        Beq     EA_MOVEM_PRE_DEC
        
        Jmp     EA_MOVEM_POST_INC       ; Post increment and control modes
        
EA_MOVEM_LIST_END   ; Ends the list loop
        Rts
        
EA_MOVEM_PRE_DEC    ; Predecrement mode
        Rol.W   #1, D5                  ; Rotate the register list mask to the left by 1
        
        Bcs     EA_MOVEM_CARRY_SET      ; Branch if the bit rotated out was 1
        
        Bcc     EA_MOVEM_CARRY_CLEAR    ; Branch if the bit rotated out was 0
        
EA_MOVEM_POST_INC   ; Post increment mode
        Ror.W   #1, D5                  ; Rotate the register list mask to the right by 1
        
        Bcs     EA_MOVEM_CARRY_SET      ; Branch if the bit rotated out was 1
        
        Bcc     EA_MOVEM_CARRY_CLEAR    ; Branch if the bit rotated out was 0
        
EA_MOVEM_CARRY_SET  ; The bit rotated out was 1
        Cmp.B   #1, D3                  ; Check to see if this is the first register being added to the list
        Beq     EA_MOVEM_FIRST_REG      ; Add the first register to the list
        
        Cmp.B   #0, D2                  ; If this bit is not in the middle of a list of consecutive ones, add a '/' and register
        Beq     EA_MOVEM_ADD_SINGLE_REG
        
        Add.B   #1, D7                  ; Increment the loop counter
        Add.B   #1, D2                  ; Increment the consecutive ones counter
        
        Cmp.B   #16, D7                 ; If this bit is the last bit, check to see if it is the last bit of a consecutive list
        Beq     EA_MOVEM_LAST_REG
        
        Jmp     EA_MOVEM_LIST_LOOP      ; Loop again
        
EA_MOVEM_CARRY_CLEAR    ; The bit rotated out was a 0
        Cmp.B   #1, D2                  ; If the bit was at the end of a consecutive list of ones, add a '-' and register
        Bgt     EA_MOVEM_ADD_LAST_REG
        
        Add.B   #1, D7                  ; Increment the loop counter
        
        Clr.L   D2                      ; Clear the counter for consecutive ones
        
        Jmp     EA_MOVEM_LIST_LOOP      ; Loop again

EA_MOVEM_FIRST_REG  ; The very first register being added to the list
        Jsr     EA_MOVEM_REG            ; Add a register without the '/' in front
        
        Clr.L   D3                      ; Clear D3 because the very first register has been placed
        
        Add.B   #1, D7                  ; Increment the loop counter
        Add.B   #1, D2                  ; Increment the consecutive ones counter
        
        Jmp     EA_MOVEM_LIST_LOOP      ; Loop again
        
EA_MOVEM_ADD_SINGLE_REG ; Adds a '/' and a register
        Move.B  #'/', (A6)+
        
        Jsr     EA_MOVEM_REG            ; Add a register
        
        Add.B   #1, D7                  ; Increment the loop counter 
        Add.B   #1, D2                  ; Increment the consecutive ones counter
        
        Jmp     EA_MOVEM_LIST_LOOP      ; Loop again
        
EA_MOVEM_LAST_REG   ; Adds the last register if it was the last bit being rotated out and it was part of a consecutive list
        Cmp.B   #1, D2                  ; Check to see if the bit was part of a consecutive list of ones
        Bgt     EA_MOVEM_ADD_LAST_REG
        
        Add.B   #1, D7                  ; Increment the loop counter
        
        Jmp     EA_MOVEM_LIST_LOOP      ; Loop again
        
EA_MOVEM_ADD_LAST_REG   ; Adds a '-' and the register, adds the last register in a consecutive list of ones
        Move.B  #'-', (A6)+
        
        Sub.B   #1, D7                  ; Move back to the previous register
        
        Jsr     EA_MOVEM_REG            ; Add the previous register as the last register in a consecutive list of ones
        
        Add.B   #2, D7                  ; Add 2 to the loop counter to make up for the 1 subtracted earlier and to move forward
        
        Clr.L   D2                      ; Clear the consecutive ones counter
        
        Jmp     EA_MOVEM_LIST_LOOP      ; Loop again
        
EA_MOVEM_REG    ; Determines the correct register to add based on the value of the loop counter
        Clr.L   D0                      ; Clear D0
        Cmp.B   #0, D7                  ; If the loop counter is 0, add D0
        Beq     EA_DN
        
        Move.B  #1, D0                  ; Move a 1 into D0
        Cmp.B   #1, D7                  ; If the loop counter is 1, add D1
        Beq     EA_DN
        
        Move.B  #2, D0
        Cmp.B   #2, D7
        Beq     EA_DN

        Move.B  #3, D0
        Cmp.B   #3, D7
        Beq     EA_DN

        Move.B  #4, D0
        Cmp.B   #4, D7
        Beq     EA_DN

        Move.B  #5, D0
        Cmp.B   #5, D7
        Beq     EA_DN

        Move.B  #6, D0
        Cmp.B   #6, D7
        Beq     EA_DN
        
        Move.B  #7, D0
        Cmp.B   #7, D7
        Beq     EA_DN
        
        Clr.L   D0
        Cmp.B   #8, D7
        Beq     EA_AN

        Move.B  #1, D0
        Cmp.B   #9, D7
        Beq     EA_AN

        Move.B  #2, D0
        Cmp.B   #10, D7
        Beq     EA_AN
        
        Move.B  #3, D0
        Cmp.B   #11, D7
        Beq     EA_AN
        
        Move.B  #4, D0
        Cmp.B   #12, D7
        Beq     EA_AN
        
        Move.B  #5, D0
        Cmp.B   #13, D7
        Beq     EA_AN
        
        Move.B  #6, D0
        Cmp.B   #14, D7
        Beq     EA_AN
        
        Move.B  #7, D0
        Cmp.B   #15, D7
        Beq     EA_AN

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
        
        RTS
        
EA_ADD_OPMODE_SOURCE    ; Finds the EA for Add if it is for the source
        Jsr     EA_ADD_ADDRESS          ; Get the source EA
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     GET9TO11                ; Get the register
        Jsr     EA_DN                   ; Add Dn
        
        RTS
        
EA_ADD_OPMODE_DEST      ; Finds the EA for Add if it is for the destination
        Jsr     GET9TO11                ; Get the register
        Jsr     EA_DN                   ; Add Dn
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_ADD_ADDRESS          ; Get the destination EA 
        
        RTS
        
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
        Rts     ; Blong edited, was blank
        
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
        
        RTS
        
;=========================================================;        
;------------------------ EA Not -------------------------;
; Jumps straight to EA_NEG because Neg and Not have the
; exact same EAs. 
;=========================================================;
EA_NOT
        Jmp     EA_NEG 
        
;=========================================================;        
;------------------------ EA Jsr -------------------------;
; Jumps straight to EA_NEG because Neg and Jsr have the
; exact same EAs. 
;=========================================================;
EA_Jsr
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
        
        RTS
                
EA_SHIFT_MEMORY ; Adds the correct EA for a memory shift
        Jsr     EA_0TO5                 ; Check for all EA except #<data>
        
        Rts
        
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
        
        RTS

;============================================;        
;--------------- EA Immediate ---------------;
; Provides EA for SubI, OrI, EorI, and CmpI.
;============================================;
EA_IMMEDIATE    ; Figures out the EA for immediate data OP codes
        Jsr     EA_IMMEDIATE_SIZE       ; Get the size of the immediate data and add to string
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     EA_IMMEDIATE_DEST       ; Add the destination EA
        
        RTS
        
EA_IMMEDIATE_SIZE   ; Determines the size of the immediate data and adds it
        Jsr     GET6TO7                 ; Isolate the size bits
                
        Cmp.B   #%01, D0                ; Immediate word
        Beq     EA_IMM_WORD
        
        Cmp.B   #%10, D0                ; Immediate long
        Beq     EA_IMM_LONG
      
        Jmp     EA_IMM_BYTE

        Rts
        
EA_IMMEDIATE_DEST   ; Determines the destination EA
        Jsr     EA_0TO5                 ; Check for all EA except #<data>
        
        Rts
      
;=================================================;  
;-------------------- EA Muls --------------------;
;=================================================;
EA_MULS ; Determines the EA for Muls
        Jsr     EA_MULS_ADDRESS         ; Get the EA
        Move.B  #',', (A6)+             ; Add a comma
        Jsr     GET9TO11                ; Get the register
        Jsr     EA_DN                   ; Add Dn
        
        RTS
        
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
        
        RTS

EA_BTST_IMM ; Gets the immediate data for the bit number
        AddA.W  #1, A3                  ; Move the pointer forward by a byte to get the next byte
        Jsr     EA_IMM_BYTE             ; Add the bit number as an immediate hex byte
        
        Jsr     EA_BTST_ADDRESS         ; Add the register to the string
        
        RTS

EA_BTST_ADDRESS ; Get the EA
        Move.B  #',', (A6)+

        Jsr     EA_0TO5                 ; Check the EA for everything but #<data>
        
        Cmp.B   #Imm_Reg, D0            ; Check if the EA is #<data>
        Beq     EA_IMM_BYTE             ; Add immediate byte for EA
        
        Rts
        
;==================================================;        
;------------------- EA Branch --------------------;
; Determines the EA for Bra, Beq, Bne, Blt, and Bhi.
;==================================================;
EA_BRANCH  ; Determines the EA for Branch codes
        Jsr     GET0TO7                 ; Get the 8 displacement bits
        
        Move.L  A3, D6                  ; Move address after the Bra word to D6
        
        Cmp.B   #0, D0                  ; If the displacement bits are 0 then get the next word
        Beq     EA_BRANCH_16_BIT
        
        Jmp     EA_BRANCH_ADD_DIS       ; Else, add the displacement to D6

EA_BRANCH_16_BIT   ; Gets the next word
        Move.W  (A3)+, D0               ; Stores the word in D0

        Jmp     EA_BRANCH_ADD_DIS       ; Add the word to D6
        
EA_BRANCH_ADD_DIS   ; Adds the displacement to the long word address in D6
        Add.W   D0, D6                  ; Add the displacement to D6
    
        Move.B  #'$', (A6)+             ; Add '$' to the string
        
        Jsr     hex_to_ASCII_L       ; Add the long word sum to the string

        RTS
                       
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
        Bcs     EA_SIGN_EXT_16
        
        Cmp.W   #$8000, D6          ; Word address is greater than 8000
        Bcc     EA_SIGN_EXT_32
        
        Rts
                
EA_SIGN_EXT_16  ; Adds 0 if the word address is 16 bit
        Move.B  #'0', (A6)+
        Move.B  #'0', (A6)+
        Move.B  #'0', (A6)+
        Move.B  #'0', (A6)+
        
        Jsr     hex_to_ASCII_W       
        
        Rts

EA_SIGN_EXT_32 ; Adds F is the word address is 32 bit
        Move.B  #'F', (A6)+
        Move.B  #'F', (A6)+
        Move.B  #'F', (A6)+
        Move.B  #'F', (A6)+
        
        Jsr     hex_to_ASCII_W   
        
        Rts
                
EA_LONG_ADDR    ; Adds $Long to string
        Move.L  (A3)+, D6           ; Move the long address into D6 and move forward in memory
        
        Move.B  #'$', (A6)+
        
        Jsr     hex_to_ASCII_L

        Rts
                

EA_IMM_BYTE ; Finds the immediate byte data
        Move.W  (A3)+, D6            ; Move the immediate byte data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+         
        Move.B  #'$', (A6)+         
        
        Jsr     hex_to_ASCII_B    ; Add the byte to the string
        
        Rts
                
EA_IMM_WORD ; Finds the immediate word data
        Move.W  (A3)+, D6            ; Move the immediate word data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+         
        Move.B  #'$', (A6)+         
        
        Jsr     hex_to_ASCII_W    ; Add the word to the string
        
        Rts
        
EA_IMM_LONG ; Finds the immediate long data
        Move.L  (A3)+, D6            ; Move the immediate long data into D6 and move forward in memory
        
        Move.B  #'#', (A6)+
        Move.B  #'$', (A6)+
        
        Jsr     hex_to_ASCII_L    ; Add the long to the string
        
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
				
GET12TO13
        CLR.L   D0
        Move.W  D4, D0
        
        Move.B  #2, D1
        LSL     D1, D0
        
        Move.B  #14, D1
        LSR     D1, D0
        
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
				
GET6AND7    
                CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#8, D1
				LSL.W 	D1, D0
				
				Move.B	#14, D1
				LSR.W	D1, D0
				
				RTS
				
GET7AND8    
                CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#7, D1
				LSL.W 	D1, D0
				
				Move.B	#14, D1
				LSR.W	D1, D0
				
				RTS				
				
GET3AND4    
                CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#11, D1
				LSL.W 	D1, D0
				
				Move.B	#14, D1
				LSR.W	D1, D0
				
				RTS
				
GETBIT5
        Clr.L   D0
        Move.W  D4, D0
        
        Move.B  #10, D1
        Lsl     D1, D0
        
        Move.B  #15, D1
        Lsr     D1, D0
        
        Rts

GET0TO7
        Clr.L   D0
        Move.W  D4, D0
        
        Move.B  #8, D1
        Lsl     D1, D0
        
        Lsr     D1, D0
        
        Rts
        
GETBIT10
        Clr.L   D0
        Move.W  D4, D0
        
        Move.B  #5, D1
        Lsl     D1, D0
        
        Move.B  #15, D1
        Lsr     D1, D0
        
        Rts
        
GET6TO7
        Clr.L   D0
        Move.W  D4, D0
        
        Move.B  #8, D1
        Lsl     D1, D0
        
        Move.B  #14, D1
        Lsr     D1, D0
        
        Rts

GET3TO8    ; 0000 0000 1100 0000 -> 11
                CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#7, D1
				LSL.W 	D1, D0
				
				Move.B	#10, D1
				LSR.W	D1, D0
				
				RTS

GET6TO11    ; 0000 0000 1100 0000 -> 11
                CLR.L	D0
				Move.W 	D4, D0
				
				Move.B	#4, D1
				LSL.W 	D1, D0
				
				Move.B	#10, D1
				LSR.W	D1, D0
				
				RTS        
				
           
;-----------Constants/Messages-------------------------------------------------
intro_stuff     DC.B    HT,'------------------------------------------------------',CR,LF,0

intro_msg       DC.B    HT,' Welcome to the Motorola 68K Instruction Disassembler',CR,LF
                DC.B    HT,' Created By: Blong Thao, Curtis Andersson, John Louie',CR,LF,0
       
start_address   DC.B    'Please enter the starting address from $0 to $00FFFFFE: ',0
end_address1    DC.B    'Please enter the ending address from $',0
end_address2    DC.B    ' to $00FFFFFE: ',0
ending          DC.B    'Thank you for using our 68K Disassembler Program!',0
ask_user        DC.B    'Would you like to run the program again? (Y/N) ',0
hit_enter_msg   DC.B    'Hit enter if you would like to see more data.',0

badAddr_input   DC.B    HT,'Address entered is not within the specified range!',CR,LF,0
odd_input       DC.B    HT,'You need to enter an even ending address',CR,LF,0
ask_error       DC.B    HT,'Please try again, on next line please input a Y or N', CR,LF,0

start_input     DS.L    2               ; Allocates space for start address
end_input       DS.L    2               ; Allocates space for end address
ask_input       DS.L    2               ; User input for Y and N, pre-end of program
hit_enter       DS.L    2               ; User input to hit enter
line_count      DS.L    1               ; Holds the display line count  
illegal_data    DS.L    80              ; Data/Instructions that we do not convert
valid_data      DS.L    80              ; Instructions that we converted
                
                END     START















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
