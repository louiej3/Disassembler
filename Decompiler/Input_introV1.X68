*-----------------------------------------------------------
* Title      : Disassembler - I/O Part
* Written by : Blong Thao
* Date       : 11/16/14
* Description: This program asks for the starting address
*               and the ending address.
*-----------------------------------------------------------
CR              EQU     $0D                 ; Carriage return
LF              EQU     $0A                 ; Line Feed
HT              EQU     $09                 ; Tab (horizontal 5 characters)
begin           EQU     $00000000           ; Lowest starting address
end             EQU     $00FFFFFE           ; Highest ending address

                ORG    $1000
START       
*-----------Introduction Message----------------------------
                LEA     INTRO, A1           ; Load introduction
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
                
                LEA     bad_input,A1        ; Not equal to 1, its a bad input, start over
                MOVE.B  #14,D0              ; Load task code for display
                TRAP    #15                 ; Display bad input message
                BRA     prompt_start        ; Go back beginning, asking for start address

valid_start     JSR     chk_bound           ; Check if the input has odd/even bounds
                CMP.W   #-1,D3              ; If -1 in D3, then input was odd
                BEQ     prompt_start        ; Go back and ask for correct input
                MOVE.L  #begin,D6           ; Store minimum address in D6
                CMP.L   D6,D3               ; If start address is lower than minimum address
                BLT     start_error         ; Then, start address is too low
                MOVEA.L D3,A5               ; store current address in A5                  

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
                LEA     bad_input,A1        ; Else, bad input
                MOVE.B  #14,D0              ; Load task code for display
                TRAP    #15                 ; Display bad input message
                BRA     prompt_end          ; Restart process

valid_end       JSR     chk_bound           ; Check if the input has odd/even bounds
                CMP.W   #-1,D3              ; If -1(FFFF), then it has odd bounds
                BEQ     prompt_end          ; Go back and ask for correct input
                MOVE.L  #end,D6             ; Move max address to compare with input
                CMP.L   D6,D3               ; Is input higher than max
                BGT     end_error           ; Input address is too high
                CMP.L   A5,D3               ; Is input at or above minimum address
                BLT     end_error           ; Input address is too low
                MOVEA.L D3,A6               ; Load ending address into its register                
                JMP     done                ; **PLACEHOLDER**
                
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
                
invalid         MOVEQ   #$0,D4              ; Invalid address
                RTS                         ; Return to start/end prompt
                
return          MOVEQ   #$1,D4              ; Valid address
                RTS                         ; Return to start/end prompt

;-----------Error Messages ----------------------------------------------------
start_error     JSR     load_bad_input      ; Print bad input error message
                JMP     prompt_start        ; Return to prompt for start address
                
end_error       JSR     load_bad_input      ; Print bad input error message
                JMP     prompt_end          ; Return to prompt for end address

load_bad_input  LEA     bad_input,A1        ; Load bad input message
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
                
done            LEA     ending,A1           ; Load ending message
                MOVE.B  #13,D0              ; Load task code for display
                TRAP    #15                 ; Display ending message
                STOP    #$00002700          ; End of program
                
;-----------Constants/Messages-------------------------------------------------
INTRO           DC.B    ' Welcome to the Motorola 68K Instruction Dis-assembler!',CR,LF
                DC.B    ' Created By: Blong Thao, Curtis Andersson, John Louie',CR,LF,0
       
start_address   DC.B    'Please enter the starting address from $0 to $00FFFFFE: ',0
end_address1    DC.B    'Please enter the ending address from $',0
end_address2    DC.B    ' to $00FFFFFE: ',0
ending          DC.B    '... More work to be done ...',0

bad_input       DC.B    HT,'Address entered is not within the specified range!',CR,LF,0
odd_input       DC.B    HT,'You need to enter an even ending address',CR,LF,0

start_input     DS.L    32              ; Allocates 2 long spaces for start address
end_input       DS.L    32              ; Allocates 2 long spaces for end address

                END    START            ; End-of-program




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
