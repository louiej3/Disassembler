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
                MOVE.L  #2,D0               ; Load task code for user input
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
                
                LEA     valid_data,A6       ; Store current address to memory
                JSR     hex_to_ASCII_L      ; Store current address to memory as string
                MOVE.B  #HT,(A6)+           ; Store TAB
                
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
                MOVEA.L A0,A6               ; Use A6 to write illegal data                
                MOVE.B  #HT,(A6)+           ; Store TAB 
                MOVE.B  #'D',(A6)+          ; Store DATA
                MOVE.B  #'A',(A6)+
                MOVE.B  #'T',(A6)+
                MOVE.B  #'A',(A6)+
                MOVE.B  #HT,(A6)+           ; Store TAB
                MOVE.B  #'$',(A6)+
                
                ; Store 4 hex digits that represent the word into memory
                CLR.L   D6
                MOVE.W  D4,D6               ; Move the word data into D6 for conversion
                JSR     hex_to_ASCII_W      ; Converts hex to ascii for the word data
                BRA     main_loop           ; Store info to memory as string

OP_CODE_TREE    ; *PLACEHOLDER*
                ;MOVE.B  #1,D7               ; Bad buffer bit set
                MOVE.B  #0,D7               ; Bad buffer bit not set               

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
