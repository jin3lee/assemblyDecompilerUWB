*-----------------------------------------------------------
* Title      :  68k Dissassembler
* Written by :  Joseph Lee and Sahith Nareddy
* Date       :
* Description:  
*-----------------------------------------------------------
    
*----------------------------------------------------------*    
*                       *SYSTEM EQU*                       *
*----------------------------------------------------------* 
CR      EQU     $0D
LF      EQU     $0A
                *FEDCBA9876543210
TEST    EQU     %0001000001000000

*ASCII TO HEX*
*numbers in hex*
zero2Hex    EQU     $30
one2Hex     EQU     $31
two2Hex     EQU     $32
three2Hex   EQU     $33
four2Hex    EQU     $34
five2Hex    EQU     $35
six2Hex     EQU     $36
seven2Hex   EQU     $37
eight2Hex   EQU     $38
nine2Hex    EQU     $39

*lowercase in hex*
a2Hex       EQU     $64
b2Hex       EQU     $65
c2Hex       EQU     $66
d2Hex       EQU     $67
e2Hex       EQU     $68
f2Hex       EQU     $69

*uppercase in hex*
AHex        EQU     $41
BHex        EQU     $42
CHex        EQU     $43
DHex        EQU     $44
EHex        EQU     $45
FHex        EQU     $46

*----------------------------------------------------------*


   
START   ORG    $1000               ; first instruction of program



PROGRAMSTART
            * 1) Display welcome message
            JSR     SUB_INTRO               *(COMPLETED)*
            
PROMPT_INPUT
            JSR     SUB_STARTADDRESS        *(COMPLETED)*
            JSR     SUB_ENDADDRESS          *(COMPLETED)*
            JSR     MAIN
            
            BRA     TERMINATE

* --------------------------------------*
*              BIG SUBROUTINES          *
* --------------------------------------*
*PRINTS WELCOME MESSAGE
SUB_INTRO
            LEA     WELCOME,A1
            JSR     PRINT_MESSAGE
            RTS
            
*ASKS USER FOR START ADDRESS AND VALIDATES
SUB_STARTADDRESS
*------------------REGISTERS-------------*
*[D1] - HOLDS THE LENGTH OF THE STARTADD *
*[A1] - POINTS TO START ADDRESS          *
*----------------------------------------*
            * 2) Prompt user for start location
            LEA     MSSG_PROMPT_START_INPUT,A1
            JSR     PRINT_MESSAGE
            
            * 3) Store start location
            LEA     STARTADD,A1
            JSR     RECIEVE_INPUT
            
            * ERROR CHECK: check if input length less than 1
            CMPI.B  #0,D1
            BLE     SUB_INPUT_AMOUNT_ERR
            
            
            * ERROR CHECK: check if input length greater than 8
            CMPI.B  #8,D1
            BGT     SUB_INPUT_AMOUNT_ERR
            
            * ERROR CHECK: check if input characters are valid characters
            *LEA     STARTADD,A1                 *LOADS THE START ADDRESS INTO A1 BEFORE CHECKING VALID CHARACTERS WITH SUBROUTINE
            JSR     CHECK_VALID_INPUT_IN_A1
            CMPI.B  #1, D7                  * Check for error
            BEQ     ERROR_CASE_ALPHA                 
            MOVE.L  D1, STARTING_ADDRESS_HEX           * Move the result to STARTING_ADDRESS_HEX [1]

            * Error Checking (Odd)
            LEA     STARTING_ADDRESS_HEX, A1           * Load 'S_ADDR_HX' for odd error
            JSR     IS_ODD                  * Check if the input address is odd
            CMPI.B  #1, D7                  * Check for error
            BEQ     ERROR_CASE_ALPHA
            
            * This subroutine is for if you encounter an error with input       
            RTS  

*ASKS USER FOR END ADDRESS AND VALIDATES
SUB_ENDADDRESS
            *!!!BUG REPORT!!!*
            *ENDING ADDRESS DOESN'T > STARTING ADDRESS IF CHARACTER '8' THROUGH 'F' 
            *IS THE FIRST CHARACTER IN ENDING ADDRESS AND LENGTH OF ADDRESS IS 8 CHARACTERS LONG*        
            ****REPORTBUGREPORTBUGREPORTBUGREPORTBUGREPORTBUGREPORTBUGREPORTBUGREPORTBUGREPORT***
            *-----------------------------------------------------------------------------------*
            
            * 4) Prompt user for end location
            LEA     MSSG_PROMPT_END_INPUT,A1
            JSR     PRINT_MESSAGE
            
            * 5) Store end location
            LEA     ENDADD,A1
            JSR     RECIEVE_INPUT
            
            * Error Checking (length)
            CMPI.B  #0, D1                  * Check if input length <= 0
            BLE     ERROR_CASE_BETA
            CMPI.B  #8, D1                  * Check if input length > 8
            BGT     ERROR_CASE_BETA
            
            * Conversion & Storage
            JSR     ASC_CONV_HEX                * Jump to ASCII2HEX
            CMPI.B  #1, D7                      * Check for error
            BEQ     ERROR_CASE_ALPHA
            MOVE.L  D1, ENDING_ADDRESS_HEX           * Move the result to ENDING_ADDRESS_HEX
            
            * Error Checking (start < end)
            MOVE.L  STARTING_ADDRESS_HEX, D2        * Move the starting address to D2
            CMP.L   D2, D1                          * Compare starting and ending address
            BLE     ERROR_CASE_BETA                 * Go to ERROR_5 if ending < starting
            
            * Error Checking (Odd)
            LEA     ENDING_ADDRESS_HEX, A1           * Move the ending address
            JSR     IS_ODD                  * Go to IS_ODD for odd address checking
            CMPI.B  #1, D7                  * Check for an error flag
            BEQ     ERROR_CASE_BETA
            
            * Inputs are valid
            MOVE.L  STARTING_ADDRESS_HEX, A5           * Store the valid input in A5
            
            
            
*CHECKS IF CHARACTERS ARE VALID AS AN ADDRESS
CHECK_VALID_INPUT_IN_A1
*---------CONDITIONS-------*
*PRE: A1 is leashed to address in memory that we are checking characters to validate
*PRE: D1 contains the amount of characters to check for validity
*---------REGISTERS--------*
*[D3] - store bytes

ASC_CONV_HEX  
            CLR.L   D2                      * Clear D2 storage
            CLR.L   D7                      * error flag
            CLR.L   D1                      * dest



* Here we check cases starting at highest ASCII values, which is lower case F
* Then move down to lower ASCII values, which is numbers
* If it's still invalid by the time we have passed numbers, thent they passed us
* something out of range.
ASC_CHECK_INVALID_CASES    
            MOVE.B  (A1)+, D2               * Read A1 into D2
            CMPI.B  #0, D2                  * Check if the byte is null, which means end of string
            BEQ     RETURN                  * If null exit out (we're done checking)
            CMPI.B  #102, D2                * ASCII val of f = 102
            BGT     ASC_ERROR               * Check if the value is greater than f's value, if it is, invalid
            CMPI.B  #97, D2                 * ASCII val of a = 97
            BGE     ASC_LOWER_CASE          * ASCII can be greater than/equal a, which means it is less than f also and in range
            CMPI.B  #70, D2                 * ASCII val of F = 70
            BGT     ASC_ERROR               * just as with lower case f, check if greater than F
            CMPI.B  #65, D2                 * Decimal ASCII value of A is 65
            BGE     ASC_UPPER_CASE                 * ASCII >= A (valid input)
            CMPI.B  #57, D2                 * Decimal value of 9 is 57
            BGT     ASC_ERROR                 * ASCII > 9 (invalid input)
            CMPI.B  #48, D2                 * Decimal ASCII value of 0 is 48
            BGE     ASC_NUMBER_CASE                 * ASCII >= 0 (valid input)
            BRA     ASC_ERROR                 * Invalid input

ASC_LOWER_CASE     
            SUBI    #87, D2                 * Convert ascii to hex
            BRA     ASC_SHIFT_LEFT          * asc shift left to shift the bits
            
ASC_UPPER_CASE     
            SUBI    #55, D2                 * ascii to Hex
            BRA     ASC_SHIFT_LEFT          * shift bits
            
ASC_NUMBER_CASE     
            SUBI    #48, D2                 * ascii to hex
            BRA     ASC_SHIFT_LEFT          * shift the bits
            
ASC_SHIFT_LEFT     
            ASL.L   #4, D1                      * dest Shift left by 4 bits
            ADD.B   D2, D1                      * add input into D1
            BRA     ASC_CHECK_INVALID_CASES     *restarts

ASC_ERROR     MOVE.B  #1, D7                  * error indicated by d7           
RETURN      RTS     

* --------------------------------------*
* --------------------------------------*
*                 MAIN                  *
* --------------------------------------* 
* --------------------------------------*

*\/\/\/\/\/ ASSIGNED VARIABLES \/\/\/\/\/\
* A2:   contains the STARRT ADDRESS in hex format
* A3:   contains the END ADDRESS in hex format      [PLEASE DO NOT CLEAR]
* A4:   used to hold location of jump table
* D3:   used for storing contents of address we are trying to decode
* D4:   copy of process data
* D5:      

MAIN
            * clear all ah duh data registers and address registers
            CLR     D0
            CLR     D1
            CLR     D2
            CLR     D3
            CLR     D4
            CLR     D5
            CLR     D6
            CLR     D7
            
            MOVE.L  TEST,$00000000  *TEST
            
            MOVE.L  #0,A0
            MOVE.L  #0,A1
            MOVE.L  #0,A3
            MOVE.L  #0,A4
            MOVE.L  #0,A5
            MOVE.L  #0,A6
            
            MOVE.L  STARTING_ADDRESS_HEX,A2 *load starting address, in hex format, into A1
            MOVE.L  ENDING_ADDRESS_HEX,A3      *load ending address in hex format, into A1
            JSR     MAIN_HELPER
            
            
MAIN_HELPER
            * note: don't clear A3!
            CMP.L   A2,A3
            BEQ     PROMPT_INPUT    * if starting address has reached ending address, restart program
            
            CLR     D3              * clear D3
            MOVE.W  (A2)+,D3        * move START ADDRESS into register D3 and post-increment it
            MOVE.L  D3,D4           * move copy of process data to D4
            CLR     D5              * clear D5
            MOVE.B  #12,D5          * shift bytes in D3 by 12 to right
            LSR.W   D5,D3
            MULU    #6,D3           * ------------------- offset is by 6
            LEA     JMPTABLE,A4     * load jump table into A4
            JSR     0(A4,D3)        * jump into the jump table like Mario
            
            
            


* --------------------------------------*
*              JUMP TABLE               *
* --------------------------------------*  

JMPTABLE    JMP     OPCODE_0000  *ORI, EORI, CMPI, SUBI  [complete sans doublechecks]
            JMP     OPCODE_0001  *MOVE.B                 [complete sans doublechecks]
            JMP     OPCODE_0010
            JMP     OPCODE_0011
            JMP     OPCODE_0100
            JMP     OPCODE_0101
            JMP     OPCODE_0110
            JMP     OPCODE_0111
            JMP     OPCODE_1000
            JMP     OPCODE_1001
            JMP     OPCODE_1010
            JMP     OPCODE_1011
            JMP     OPCODE_1100
            JMP     OPCODE_1101
            JMP     OPCODE_1110           
            JMP     OPCODE_1111  *special reserve for garbage data (no proper opcodes have 1111)

* --------------------------------------*
*            OPCODE TABLE               *
* --------------------------------------*

* ORI, EORI, CMPI, SUBI
OPCODE_0000
            LEA     MSSG_DEBUG_1,A1
            JSR     PRINT_MESSAGE
            BRA     TERMINATE
           

* MOVE.B
OPCODE_0001
            LEA     MSSG_DEBUG_3,A1
            JSR     PRINT_MESSAGE
            BRA     TERMINATE
OPCODE_0010
OPCODE_0011
OPCODE_0100
OPCODE_0101
OPCODE_0110
OPCODE_0111
OPCODE_1000
OPCODE_1001
OPCODE_1010
OPCODE_1011
OPCODE_1100
OPCODE_1101
OPCODE_1110 

OPCODE_1111

TEST_DEBUG
            LEA     MSSG_DEBUG_2,A1
            JSR     PRINT_MESSAGE
            BRA     TERMINATE
            
    

       
* --------------------------------------*
*          ERROR SUBROUTINES            *
* --------------------------------------*  

*Input less than 1 OR greater than 8
SUB_INPUT_AMOUNT_ERR
            LEA     MSSG_ERROR_INPUT_AMOUNT,A1
            JSR     PRINT_MESSAGE
            BRA     SUB_STARTADDRESS
            
ERROR_CASE_ALPHA
            LEA     ERROR_1,A1
            JSR     PRINT_MESSAGE
            BRA     SUB_STARTADDRESS
            
ERROR_CASE_BETA
            LEA     ERROR_1,A1
            JSR     PRINT_MESSAGE
            BRA     SUB_ENDADDRESS
            
IS_ODD      CLR.L   D1                      * reset
            CLR.L   D7                      * clear D7
            MOVE.L  (A1),D1                 * store A1 to D1
            DIVU    #2, D1                  * divide contents of D1 by two
            SWAP    D1                      * Exchange the quotient with the remainder
            CMPI.B  #1, D1                  * err check
            BEQ     IS_ERROR_ODD
            BRA     RETURN_ODD
            
IS_ERROR_ODD  MOVE.B  #1, D7
RETURN_ODD    RTS

   
* --------------------------------------*
*          GENERIC SUBROUTINES          *
* --------------------------------------*

* Prints a message
PRINT_MESSAGE
            MOVE.B  #14,D0
            TRAP    #15
            RTS

* Recieves input from the user
RECIEVE_INPUT
            MOVE.B	#2,D0
            TRAP	#15
            RTS
            
   
            
            
* --------------------------------------*
*            TERMINATE(STOP SIM)        *
* --------------------------------------*
TERMINATE   MOVE.B  #9,D0       
            TRAP    #15
        
* --------------------------------------*
*                VARIABLES              *
* --------------------------------------*

* The welcome message we display.
WELCOME
            DC.B ' _   _  _________________  ______ _   _______ _____  _       ___  ______ ',CR,LF
            DC.B '| \ | ||  ___| ___ \  _  \ | ___ \ | | | ___ \  __ \| |     / _ \ | ___ \',CR,LF
            DC.B '|  \| || |__ | |_/ / | | | | |_/ / | | | |_/ / |  \/| |    / /_\ \| |_/ /',CR,LF
            DC.B '| . ` ||  __||    /| | | | | ___ \ | | |    /| | __ | |    |  _  ||    / ',CR,LF
            DC.B '| |\  || |___| |\ \| |/ /  | |_/ / |_| | |\ \| |_\ \| |____| | | || |\ \ ',CR,LF
            DC.B '\_| \_/\____/\_| \_|___/   \____/ \___/\_| \_|\____/\_____/\_| |_/\_| \_|',CR,LF
            DC.B 'By Joseph Lee & Sahith Nareddy',CR,LF
            DC.B '',CR,LF
            DC.B '',CR,LF,CR,LF,0

MSSG_PROMPT_START_INPUT
            DC.B    'Please enter starting memory location:',CR,LF,CR,LF,0
            
MSSG_PROMPT_END_INPUT
            DC.B    'Please enter ending memory location:',CR,LF,CR,LF,0
            
MSSG_ERROR_INPUT    DC.B 'There is an error with your input.',CR,LF,CR,LF,0

MSSG_ERROR_INPUT_AMOUNT    DC.B 'There is an error with your input. There must be 1 through 8 hex characters.',CR,LF,CR,LF,0

MSSG_DEBUG_1
            DC.B    'You hit the OPCODE_0000',CR,LF,CR,LF,0

MSSG_DEBUG_2
            DC.B    'You hit debug',CR,LF,CR,LF,0     

MSSG_DEBUG_3
            DC.B    'You hit OPCODE_0001',CR,LF,CR,LF,0         
            

STARTADD    
            DS.B    80
ENDADD    
            DS.B    80


STARTING_ADDRESS_HEX   DS.L    1                       * allocate storage space for the starting address in hex
ENDING_ADDRESS_HEX   DS.L    1                       * allocate storage space for the ending address in hex


ERROR_1    DC.B    'Error: Invalid Input Address',CR,LF,0
ERROR_3    DC.B    'Error: Invalid Input Address (Odd)',CR,LF,0
ERROR_5    DC.B    'Error: Invalid Input Address (start > end)',CR,LF,0
            END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
