*---------------------------------------------------------------------------*
* Title      : 68K Disassembler
* Written by : Team Circle
* Date       : 12/05/14
* Description: Scans a section of memory and converts its
*              contents to a listing of valid assembly 
*              language instructions
*---------------------------------------------------------------------------*

*---------------------------------------------------------------------------*
* System Equates                                                 
*---------------------------------------------------------------------------*
CR          EQU     $0D                     * ASCII for Carriage Return
LF          EQU     $0A                     * ASCII for Line Feed 
STACK       EQU     $7000                   * Initial Stack Pointer                         
            
*---------------------------------------------------------------------------*
* Reserved Registers
*---------------------------------------------------------------------------*  
* D0 - I/O
* D1 - Temporary storage of processing data
* D3 - [PUSH_STACK]
* D4 - Opcode size (0 - byte; 1- word; 2-long)
* D5 - Processing data
* D6 - Loop counter to print 30 lines
* D7 - Error flag
* A2 - [STACK POINTER]
* A5 - Processing address in hex

*---------------------------------------------------------------------------*
* Start and loop program
*---------------------------------------------------------------------------*  
            ORG     $1000
            LEA     STACK,SP
START:            
            JSR     INTRO                 
PROGLP      JSR     START_ADDR
            JSR     END_ADDR
            LEA     ENDLINE_M,A1           * Add a new line
            MOVE.B  #14, D0                  * Display A1
            TRAP    #15
            
            JMP     MAIN
            
*---------------------------------------------------------------------------*
* INTRO: Display the introduction of the program
*---------------------------------------------------------------------------*
INTRO       LEA     WELCOME,A1              * Load PROMPT_START
            MOVE.B  #14,D0                  * Display A1
            TRAP    #15
            RTS
TESTING     

            LSR.W   #5,D0
            LSR.W   (A1)
            LSR.W   (A2)+
            LSR.W   -(A3)
            LSR.W   $1234
            LSR.W   $12345678 

            
            LSR.B   #5,D0
            LSR.W   #5,D0
            LSR.W   (A1)

            ASR.B   D1,D0
            ASR.B   #5,D0
            ASR.W   #5,D0
            ASR.W   (A1)

            ROR.B   D1,D0
            ROR.B   #5,D0
            ROR.W   #5,D0
            ROR.W   (A1)


            RTS
*---------------------------------------------------------------------------*
* START_ADDR: Compute the starting address
*---------------------------------------------------------------------------*
START_ADDR
            * Output
            LEA     PROMPT_START,A1         * Load PROMPT_START 
            MOVE.B  #14,D0                  * Display PROMPT_START
            TRAP    #15
    
            * Input
            LEA     VR_S_ADDR,A1            * Load VR_S_ADDR
            MOVE.B  #2,D0                   * Ask user for input
            TRAP    #15
            
            * Error Checking (length)
            CMPI.B  #0, D1                  * Check if input length <= 0
            BLE     ERROR_1
            CMPI.B  #8, D1                  * Check if input length > 8
            BGT     ERROR_1
            
            * Conversion & Storage
            JSR     ASCII2HEX               * Jump to ASCII2HEX
            CMPI.B  #1, D7                  * Check for error
            BEQ     ERROR_1                 
            MOVE.L  D1, S_ADDR_HX           * Move the result to S_ADDR_HX 
            
            * Error Checking (Odd)
            LEA     S_ADDR_HX, A1           * Load 'S_ADDR_HX' for odd error
            JSR     IS_ODD                  * Check if the input address is odd
            CMPI.B  #1, D7                  * Check for error
            BEQ     ERROR_3
            
            * Return
            RTS     
*---------------------------------------------------------------------------*
* END_ADDR: Compute the ending address
*---------------------------------------------------------------------------*
END_ADDR
            * Output
            LEA     PROMPT_END,A1           * Load PROMPT_END
            MOVE.B  #14,D0                  * Display PROMPT_END
            TRAP    #15

            * Input
            LEA     VR_E_ADDR,A1            * Load VR_E_ADDR
            MOVE.B  #2,D0                   * Ask user for input
            TRAP    #15
            
            * Error Checking (length)
            CMPI.B  #0, D1                  * Check if input length <= 0
            BLE     ERROR_2
            CMPI.B  #8, D1                  * Check if input length > 8
            BGT     ERROR_2
            
            * Conversion & Storage
            JSR     ASCII2HEX               * Jump to ASCII2HEX
            CMPI.B  #1, D7                  * Check for error
            BEQ     ERROR_2
            MOVE.L  D1, E_ADDR_HX           * Move the result to E_ADDR_HX
            
            * Error Checking (start > end case)
            MOVE.L  S_ADDR_HX, D2           * Move the starting address to D2
            CMP.L   D2, D1                  * Compare starting and ending address
            BLS     ERROR_5                 * Go to ERROR_5 if ending < starting
            
            * Error Checking (Odd case)
            LEA     E_ADDR_HX, A1           * Move the ending address
            JSR     IS_ODD                  * Go to IS_ODD for odd address checking
            CMPI.B  #1, D7                  * Check for an error flag
            BEQ     ERROR_4
            
            * Inputs are valid
            MOVE.L  S_ADDR_HX, A5           * Store the valid input in A5
            
            RTS
            
*---------------------------------------------------------------------------*
* ERROR_1: Address error (Invalid starting address)
*---------------------------------------------------------------------------*
ERROR_1
            LEA     ERRMSG_1, A1            * Load ERRMSG_1
            MOVE.B  #14, D0                 * Display ERRMSG_1
            TRAP    #15
            JMP     START_ADDR              * Jump to START_ADDR
    
*---------------------------------------------------------------------------*
* ERROR_2: Address error (Invalid ending address)
*---------------------------------------------------------------------------*
ERROR_2
            LEA     ERRMSG_1, A1            * Load ERRMSG_1
            MOVE.B  #14, D0                 * Display ERRMSG_1
            TRAP    #15
            JMP     END_ADDR                * Jump to END_ADDR

*---------------------------------------------------------------------------*
* ERROR_3: Address error (Odd starting address)
*---------------------------------------------------------------------------*
ERROR_3
            LEA     ERRMSG_3, A1
            MOVE.B  #14, D0
            TRAP    #15
            JMP     START_ADDR
   
*---------------------------------------------------------------------------*
* ERROR_4: Address error (Odd ending address)
*---------------------------------------------------------------------------*         
ERROR_4
            LEA     ERRMSG_3, A1
            MOVE.B  #14, D0
            TRAP    #15
            JMP     END_ADDR
          
*---------------------------------------------------------------------------*
* ERROR_3: Address error (Ending address is less than starting address)
*---------------------------------------------------------------------------*
ERROR_5
            LEA     ERRMSG_5, A1
            MOVE.B  #14, D0
            TRAP    #15
            JMP     END_ADDR
  
*---------------------------------------------------------------------------*
* ASCII2HEX: Convert ASCii to Hexadecimal
* Reserved registers: A1 = Source, D1 = Destination, D2 = Byte, D7 = Error
*---------------------------------------------------------------------------*
ASCII2HEX   CLR.L   D1                      * Clear the destination 
            CLR.L   D7                      * Set the error flag to 0
            CLR.L   D2                      * Clear D2 for temp storage
            
ASC2HXLP    MOVE.B  (A1)+, D2               * Read a byte to D2
            CMPI.B  #0, D2                  * Check for NULL (indicates the end of source)
            BEQ     RETURN                  * If it's NULL, go to return
            CMPI.B  #102, D2                * Decimal ASCII value of f is 102
            BGT     ASC_ERR                 * ASCII > f (invalid input) 
            CMPI.B  #97, D2                 * Decimal ASCII value of a is 97
            BGE     ASC_LOW                 * ASCII >= a (valid input)
            CMPI.B  #70, D2                 * Decimal ASCII value of F is 70
            BGT     ASC_ERR                 * ASCII > F (invalid input)
            CMPI.B  #65, D2                 * Decimal ASCII value of A is 65
            BGE     ASC_UPP                 * ASCII >= A (valid input)
            CMPI.B  #57, D2                 * Decimal value of 9 is 57
            BGT     ASC_ERR                 * ASCII > 9 (invalid input)
            CMPI.B  #48, D2                 * Decimal ASCII value of 0 is 48
            BGE     ASC_NUM                 * ASCII >= 0 (valid input)
            BRA     ASC_ERR                 * Invalid input

ASC_LOW     SUBI    #87, D2                 * Convert the ASCII input to Hex
            BRA     ASC_SFT                 * Go to ASC_SFT to shift the bits
            
ASC_UPP     SUBI    #55, D2                 * Convert the ASCII input to Hex
            BRA     ASC_SFT                 * Go to ASC_SFT to shift the bits
            
ASC_NUM     SUBI    #48, D2                 * Convert the ASCII input to Hex
            BRA     ASC_SFT                 * Go to ASC_SFT to shift the bits
            
ASC_SFT     ASL.L   #4, D1                  * Shift the dest to left by 4 bits
            ADD.B   D2, D1                  * Add the converted input to D1
            BRA     ASC2HXLP                * Loop

ASC_ERR     MOVE.B  #1, D7                  * Set the error flag to 1            
RETURN      RTS     

*---------------------------------------------------------------------------*
* ASCII2HEX: Convert ASCii to Hexadecimal
* Reserved registers: A1 = Source, D3 = Destination, D2 = Byte, D7 = Error
*---------------------------------------------------------------------------*
ASCII2HEX2STACK
            CLR.L   D3                      * Clear the destination 
            CLR.L   D7                      * Set the error flag to 0
            CLR.L   D2                      * Clear D2 for temp storage
            
ASC2HXLP2STACK
            MOVE.B  (A1)+, D2               * Read a byte to D2
            CMPI.B  #0, D2                  * Check for NULL (indicates the end of source)
            BEQ     RETURN2STACK                  * If it's NULL, go to return
            CMPI.B  #102, D2                * Decimal ASCII value of f is 102
            BGT     ASC_ERR2STACK                 * ASCII > f (invalid input) 
            CMPI.B  #97, D2                 * Decimal ASCII value of a is 97
            BGE     ASC_LOW2STACK                 * ASCII >= a (valid input)
            CMPI.B  #70, D2                 * Decimal ASCII value of F is 70
            BGT     ASC_ERR2STACK                 * ASCII > F (invalid input)
            CMPI.B  #65, D2                 * Decimal ASCII value of A is 65
            BGE     ASC_UPP2STACK                 * ASCII >= A (valid input)
            CMPI.B  #57, D2                 * Decimal value of 9 is 57
            BGT     ASC_ERR2STACK                 * ASCII > 9 (invalid input)
            CMPI.B  #48, D2                 * Decimal ASCII value of 0 is 48
            BGE     ASC_NUM2STACK                 * ASCII >= 0 (valid input)
            BRA     ASC_ERR2STACK                 * Invalid input

ASC_LOW2STACK
            SUBI    #87, D2                 * Convert the ASCII input to Hex
            BRA     ASC_SFT2STACK                 * Go to ASC_SFT to shift the bits
            
ASC_UPP2STACK
            SUBI    #55, D2                 * Convert the ASCII input to Hex
            BRA     ASC_SFT2STACK                 * Go to ASC_SFT to shift the bits
            
ASC_NUM2STACK
            SUBI    #48, D2                 * Convert the ASCII input to Hex
            BRA     ASC_SFT2STACK                * Go to ASC_SFT to shift the bits
            
ASC_SFT2STACK
            ASL.L   #4, D3                  * Shift the dest to left by 4 bits
            ADD.B   D2, D3                  * Add the converted input to D1
            BRA     ASC2HXLP2STACK                * Loop

ASC_ERR2STACK
            MOVE.B  #1, D7                  * Set the error flag to 1            
RETURN2STACK
            RTS  
*---------------------------------------------------------------------------*
* HEX2ASCII: Convert Hexadecimal to ASCii 
* Reserved registers: A1 = Destination, D1 = Source, D2 = Size, D7 = Byte
*---------------------------------------------------------------------------*
HEX2ASCII   CMPI.B  #8, D2                  * Check to see if the size is long
            BEQ     HEX_LOOP
            SWAP    D1
            CMPI.B  #2,D2
            BNE     HEX_LOOP
            LSL.L   #8,D1
           
HEX_LOOP    ROL.L   #4, D1                  * Roll D1 to left
            MOVE.L  D1, D3                  * Move D1 to D3
            ANDI.L  #$F,D3                  * Retrieve the right most 4 bits
            CMPI.B  #9, D3                  * Compare te digit
            BGT     HEX_CHAR              
            ADDI.B  #48,D3                  * Add 48 for numerical output
            BRA     HEX_CONT
            
HEX_CHAR    ADDI.B  #55,D3                  * Add 55 for character output

HEX_CONT    MOVE.B  D3, (A1)+               * Place into A1
            SUBI    #1, D2                  * Decrement the size
            CMPI.B  #0, D2                  * Check if D2 is 0
            BNE     HEX_LOOP                * Loop
            MOVE.B  #$0,(A1)                * Null terminator
            RTS
*---------------------------------------------------------------------------*
* HEX2ASCII2STACK: Convert Hexadecimal to ASCii 
* Reserved registers: A1 = Destination, D1 = Source, D2 = Size, D7 = Byte, PUSHES FROM D3 INTO STACK
*---------------------------------------------------------------------------*
HEX2ASCII2STACK
            CMPI.B  #8, D2                  * Check to see if the size is long
            BEQ     STACK_HEX_LOOP
            SWAP    D1
            CMPI.B  #2,D2
            BNE     STACK_HEX_LOOP
            LSL.L   #8,D1
           
STACK_HEX_LOOP    
            ROL.L   #4, D1                  * Roll D1 to left
            MOVE.L  D1, D3                  * Move D1 to D3
            ANDI.L  #$F,D3                  * Retrieve the right most 4 bits
            CMPI.B  #9, D3                  * Compare te digit
            BGT     STACK_HEX_CHAR              
            ADDI.B  #48,D3                  * Add 48 for numerical output
            BRA     STACK_HEX_CONT
            
STACK_HEX_CHAR    
            ADDI.B  #55,D3                  * Add 55 for character output

STACK_HEX_CONT    
            BSR     PUSH_STACK              *PLACE INTO STACK
            SUBI    #1, D2                  * Decrement the size
            CMPI.B  #0, D2                  * Check if D2 is 0
            BNE     STACK_HEX_LOOP                * Loop
            MOVE.B  #$0,(A1)                * Null terminator
            RTS


*---------------------------------------------------------------------------*
* IS_ODD: Check whether the source address is odd
* Reserved registers: A1 = Source, D1 = Result, D7 = error flag
*---------------------------------------------------------------------------*
IS_ODD      CLR.L   D1                      * Clear the result
            CLR.L   D7                      * Set the error flag to 0
            MOVE.L  (A1),D1                * Temp store the checking address to D1
            DIVU    #2, D1                  * Divide the result by 2
            SWAP    D1                      * Swap remainder with quotient
            CMPI.B  #1, D1                  * Check for error
            BEQ     IS_ODD_ERR
            RTS
            
IS_ODD_ERR  MOVE.B  #1, D7
            RTS

*---------------------------------------------------------------------------**---------------------------------------------------------------------------**---------------------------------------------------------------------------*
* MAINDEBUG                    
* A2: STACK POINTER                                                      MAIN                                                                        MAIN
* A5: Processing address
*
* D3: USED FOR PUSHING INTO STACK
*     To push into stack => MOVE.W #DATA,D3 
*                           BSR    PUSH_STACK
*     To print stack     => BSR    PRINT_STACK 
*     To clear stack     => BSR    CLEAR_STACK
*---------------------------------------------------------------------------**---------------------------------------------------------------------------**---------------------------------------------------------------------------*  
MAIN        
            *initialize stack pointer
            MOVE.W  #0,COUNTER
            MOVEA.W #STACK,A2
            MOVE.B  #' ',D3
            BSR     PUSH_STACK
            BSR     PUSH_STACK
            BSR     PUSH_STACK
            
            * clear registers for temp storage
            CLR.L   D0                   
            CLR.L   D1                   
            MOVEA.L #0, A1                
            
            MOVE.L  A5,D1                   * check to see if the address is fully read
            MOVE.L  A5,S_ADDR_HX
            CMP.L   E_ADDR_HX,D1
            BGE     REPEAT                  * go to repeat for user action

            LEA     TMPOUTPUT,A1            * allocate storage to hold output
            MOVE.B  #8,D2                   * set the output size
            JSR     HEX2ASCII               
            LEA     TMPOUTPUT,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            CLR.L    D5                      * clear the processing data
            MOVE.W  (A5)+,D5                 * copy the currently processing data in A5 over to D5
                                             * advance the current instruction pointer to the next
                                             * instruction in memory
*----------------------------------------*
* Registers          
* [D1] - COPY OF D5
* [D5] - DATA TO BE PROCESSED
* [D6] - COUNTER FOR LINES PROCESSED
*
* [D4]      - ERROR FLAG BEFORE PRINTING
* [STACK]   - PRINTS PROCESS DATA
* [COUNTER] - KEEPS TRACK OF STACK INCREMENT
*
* [A1] - USED FOR JUMPING/PRINTING
*
*----------------------------------------*

            
            *Processing the first 4 most significant bits 
            MOVE.L  D5,D1                    * copy the current processing data to D1
            MOVE.B  #12,D2                   * shift to right by 12 bits
            LSR.W   D2,D1             		 * [D2] Temporarily used D2 for shifting bits
            MULU    #6,D1                    * form offset
            LEA     JMPTABLE,A1              * index into table
            JSR     0(A1,D1)                 * jump indirect with index
            
            *SECURED EA*
            CMP.B   #1,D4                    * ERROR FLAG CHECK [ERROR WHEN D4 == 1]
            BNE     OUTPUT_PROCESSED_DATA    * PRINTS PROCESSED OP-CODE & EA
            BSR     OP_DATA                  * PRINT ERROR MESSAGE "DATA"
            BSR     CLEAR_STACK              * CLEARS THE STACK 
            MOVE.B  #0,D4                    * RESETS [D4] ERROR FLAG
            BRA     DISPLAY_30_LINES         * GO TO LAST STEP
           
OUTPUT_PROCESSED_DATA       
            MOVE.B  #$D,D3                  *carriage return
            BSR     PUSH_STACK
            MOVE.B  #$A,D3                  *new line feed
            BSR     PUSH_STACK
            MOVE.B  #$0,D3                  *null
            BSR     PUSH_STACK
     
            BSR     PRINT_QUEUE
            MOVE.B  #0,D4                    * RESETS [D4] ERROR FLAG
DISPLAY_30_LINES
            * display 30 lines per page
            ADDI.B  #1,D6
            CMPI.B  #30,D6
            BGE     NEXTLINES
            BRA     MAIN
          
*---------------------------------------------------------------------------*
* NEXTLINES: receive input from user to print the next 30 lines
*---------------------------------------------------------------------------*  
NEXTLINES   CLR.B   D6
            LEA     DISP_NEXT,A1
            MOVE.B  #14,D0
            TRAP    #15
            LEA     TMPINPUT,A1
            MOVE.B  #2,D0
            TRAP    #15
            JMP     MAIN
  
*---------------------------------------------------------------------------*
* JMPTABLE: OP code jump/branch table used to decode and display opcodes
*---------------------------------------------------------------------------*  
JMPTABLE    JMP     OP0000  * CMPI/ORI/BTST/EORI/SUBI                       *FINISHED - 
            JMP     OP0001  * MOVE.B                                        *FINISHED - 
            JMP     OP0010  * MOVE.L/MOVEA.L                                *FINISHED - 
            JMP     OP0011  * MOVE.W/MOVEA.W                                *FINISHED - 
            JMP     OP0100  * MOVEM/LEA/NEG/NOT/JSR/RTS                     *FINISHED - 
            JMP     OP0101  * ADDQ                                          *FINISHED - 
            JMP     OP0110  * BRA/Bcc (BEQ/BNE/BLT/BHI)                     *FINISHED - 
            JMP     OP0111  * MOVEQ (unassigned)                            *FINISHED - NEVER ASSIGNED
            JMP     OP1000  * DIVS                                          *FINISHED - 
            JMP     OP1001  * SUB/SUBA                                      *FINISHED - 
            JMP     OP1010  * Unassigned                                    *FINISHED - NEVER ASSIGNED
            JMP     OP1011  * CMP/EOR/CMPA                                  *FINISHED - 
            JMP     OP1100  * MULS/AND                                      *FINISHED - 
            JMP     OP1101  * ADD/ADDA                                      *FINISHED - 
            JMP     OP1110  * LSR/LSL/ASR/ASL/ROL/ROR                       *FINISHED - LSR/LSL
            JMP     OP1111  * Special/Reserved
            
*---------------------------------------------------------------------------*
* OP0000: decode CMPI/ORI/BTST/SUBI/EORI
*---------------------------------------------------------------------------*           
OP0000                                                                                  
            CLR.L   D1          * to temporarily store the address to process
            CLR.L   D0  
            CLR.L   D4                 
            MOVEA.L #0, A1                
            * Check for ORI (0000 0000 xx (size) xxx (EA mode) xxx(EA reg)
            * Check if bit 11,10,9,8 are 0000)
            MOVE.L  D5,D1
            ANDI.L  #$0F00,D1
            CMPI.L  #$0000,D1   * if they are 0000, it is ORI
            BEQ     OP_ORI

            * check for CMPI (0000 1100 xx (size) xxx (EA mode) xxx (EA reg)
            * check if bit 11,10,9,8 are 1100
            CLR.L   D1
            MOVE.L  D5,D1
            ANDI.L  #$0F00,D1
            CMPI.L  #$0C00,D1
            BEQ     OP0000_CMPI
            
            * check for SUBI
            CLR.L   D1
            MOVE.L  D5,D1
            ANDI.L  #$0F00,D1
            CMPI.L  #$0400,D1
            BEQ     OP_SUBI
            
            * check for EORI
            CLR.L   D1
            MOVE.L  D5,D1
            ANDI.L  #$0F00,D1
            CMPI.L  #$0A00,D1
            BEQ     OP_EORI
            
            * check for BTST
            CLR.L   D1
            MOVE.L  D5,D1
            ROR.L   #8,D1
            ANDI.L  #$1,D1
            CMPI.B  #$1,D1
            BEQ     OP_BTST
            CLR.L   D1
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03FF,D1
            CMPI.L  #%000100000,D1
            BEQ     OP_BTST


            * OP0000 series other than ORI/CMPI/BTST/EORI
            JMP     OP_DATA
            
*---------------------------------------------------------------------------*
* OP_BTST: display BTST
*---------------------------------------------------------------------------* 
OP_BTST       
            *FIGURE OUT IF it is : Dn,<ea> or #<data>,<ea>
            *bits #8 indicates which
            *0 - #immediate format
            *1 - Dn format
            CLR.L   D1
            MOVE.L  D5,D1
            ROR.L   #8,D1
            ANDI.L  #1,D1
            CMPI.B  #1,D1
            BNE     OP_BTST_IMMEDIATE

           
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT
           MOVE.B   #$02,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
           ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
           ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 
            
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'T',D3
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            MOVE.B  #'T',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
            BRA     OP0000_RETURN_BTST
            
            
            *MOVE **** OR **** CMPI
            
OP_BTST_IMMEDIATE              
 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT
           MOVE.B   #$82,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'T',D3
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            MOVE.B  #'T',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK

OP0000_BTST_B
            *GET DATA FROM ADDQ AND PRINT #0-8
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$01C0,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 

            *GRAB #IMMEDIATE DATA AS WORD SIZE
           * Reserved registers: A1 = Destination, D1 = Source, D2 = Size, D7 = Byte
           * MOVE.W    (A5)+,D1
           * MOVE.B  #' ',D3
           * BSR     PUSH_STACK
           * MOVE.B  #'#',D3
           * BSR     PUSH_STACK
           * BSR     HEX2ASCII2STACK
           * BSR     PUSH_STACK
            
            MOVE.B  #' ',D3
            BSR     PUSH_STACK
            MOVE.B  #'#',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            BRA     OP0000_RETURN_BTST
OP0000_RETURN_BTST
            
            RTS


*---------------------------------------------------------------------------*
* OP_EORI: decode and display EORI
*---------------------------------------------------------------------------* 
OP_EORI
                       

 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT
           MOVE.B   #$80,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'R',D3
            BSR     PUSH_STACK
            MOVE.B  #'I',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            *FIGURE OUT SIZE*
            *00 = BYTE
            *01 = WORD
            *10 = LONG
            * BITS 7&6
            
            *COMPARE TO SEE IF IT IS BYTE/WORD/LONG SIZE
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.B  #%00,D1
            BEQ     OP0000_EOR_B
            ANDI.L  #$03,D1
            CMPI.B  #%01,D1
            BEQ     OP0000_EOR_W
            ANDI.L  #$03,D1
            CMPI.B  #%10,D1
            BEQ     OP0000_EOR_L
          
OP0000_EOR_B
            
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%000000111000000,D5   *Add.B  BITS 8-6 TO INDICATE A "(XXX).W" Register (000) 

            
            BRA     OP0000_RETURN_EOR
OP0000_EOR_W
            
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000111000000,D5   *Add.B  BITS 8-6 TO INDICATE A "(XXX).W" Register (000) 

            
            BRA     OP0000_RETURN_EOR
OP0000_EOR_L
            
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000100111000000,D5   *Add.B  BITS 8-6 TO INDICATE A "(XXX).W" Register (000) 


OP0000_RETURN_EOR       
            MOVE.B  #' ',D3
            BSR     PUSH_STACK
            MOVE.B  #'#',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
            RTS

*---------------------------------------------------------------------------*
* OP_SUBI: decode SUBI.B/.W/.L
*---------------------------------------------------------------------------* 
OP_SUBI
           
 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT
           MOVE.B   #$80,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            MOVE.B  #'U',D3
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'I',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            *FIGURE OUT SIZE*
            *00 = BYTE
            *01 = WORD
            *10 = LONG
            * BITS 7&6
            
            *COMPARE TO SEE IF IT IS BYTE/WORD/LONG SIZE
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.B  #%00,D1
            BEQ     OP0000_SUB_B
            ANDI.L  #$03,D1
            CMPI.B  #%01,D1
            BEQ     OP0000_SUB_W
            ANDI.L  #$03,D1
            CMPI.B  #%10,D1
            BEQ     OP0000_SUB_L
          
OP0000_SUB_B
            
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%000000111000000,D5   *Add.B  BITS 8-6 TO INDICATE A "(XXX).W" Register (000) 

            
            BRA     OP0000_RETURN_SUBI
OP0000_SUB_W
            
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000111000000,D5   *Add.B  BITS 8-6 TO INDICATE A "(XXX).W" Register (000) 

            
            BRA     OP0000_RETURN_SUBI
OP0000_SUB_L
            
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000001111000000,D5   *Add.B  BITS 8-6 TO INDICATE A "(XXX).W" Register (000) 
                    
OP0000_RETURN_SUBI            
            MOVE.B  #' ',D3
            BSR     PUSH_STACK
            MOVE.B  #'#',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
            RTS

            
*---------------------------------------------------------------------------*
* OP_DATA : unidentified opcode
*---------------------------------------------------------------------------* 
OP_DATA
            CLR.L   D0                   
            CLR.L   D1     
            CLR.L   D4                    
            MOVEA.L #0, A1             
            CLR.L   D7
            MOVE.B  #1,D7                   * error flag is true
            
            LEA     DISP_DATA,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            JMP     EA_DATA
           
           
*---------------------------------------------------------------------------*
* EA_DATA
*---------------------------------------------------------------------------*       
EA_DATA     LEA     TMPOUTPUT,A1    * load the temporarily stored output address
            MOVE.L  D5,D1           * transfer the processing data to D1
            MOVE.L  #4,D2           * set to word size
            JSR     HEX2ASCII       * prepare output in ascii
            LEA     DISP_HEX,A1     * display $ symbol
            MOVE.B  #14,D0      
            TRAP    #15
            LEA     TMPOUTPUT,A1    * display with a new line
            MOVE.B  #13,D0
            TRAP    #15

            RTS
            
*---------------------------------------------------------------------------*
* OP_CMPI : decode CMPI and its size
*---------------------------------------------------------------------------*          
OP0000_CMPI

            
 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT
           MOVE.B   #$82,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'C',D3
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'P',D3
            BSR     PUSH_STACK
            MOVE.B  #'I',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            *FIGURE OUT SIZE*
            *00 = BYTE
            *01 = WORD
            *10 = LONG
            * BITS 7&6
            
            *COMPARE TO SEE IF IT IS BYTE/WORD/LONG SIZE
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.B  #%00,D1
            BEQ     OP0000_CMPI_B
            CMPI.B  #%01,D1
            BEQ     OP0000_CMPI_W
            ANDI.L  #$03,D1
            CMPI.B  #%10,D1
            BEQ     OP0000_CMPI_L

OP0000_CMPI_B
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
*GET DATA FROM ADDQ AND PRINT #0-8
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$01C0,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            BRA     OP0000_RETURN_CMPI

OP0000_CMPI_W
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
*GET DATA FROM ADDQ AND PRINT #0-8
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$01C0,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            BRA     OP0000_RETURN_CMPI

OP0000_CMPI_L
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            *GET DATA FROM ADDQ AND PRINT #0-8
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$03C0,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
OP0000_RETURN_CMPI


            
            RTS
 
*---------------------------------------------------------------------------*
* OP_ORI : decode ORI and its size
*---------------------------------------------------------------------------* 
OP_ORI      
         
 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT
           MOVE.B   #$82,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'R',D3
            BSR     PUSH_STACK
            MOVE.B  #'I',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            *FIGURE OUT SIZE*
            *00 = BYTE
            *01 = WORD
            *10 = LONG
            * BITS 7&6
            
            *COMPARE TO SEE IF IT IS BYTE/WORD/LONG SIZE
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.B  #%00,D1
            BEQ     OP0000_ORI_B
            CMPI.B  #%01,D1
            BEQ     OP0000_ORI_W
            ANDI.L  #$03,D1
            CMPI.B  #%10,D1
            BEQ     OP0000_ORI_L

OP0000_ORI_B
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
*GET DATA FROM ADDQ AND PRINT #0-8
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$01C0,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            BRA     OP0000_RETURN_ORI

OP0000_ORI_W
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
*GET DATA FROM ADDQ AND PRINT #0-8
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$01C0,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            BRA     OP0000_RETURN_ORI

OP0000_ORI_L
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            *GET DATA FROM ADDQ AND PRINT #0-8
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$F03F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$03C0,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 
            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
OP0000_RETURN_ORI


            
            RTS

        
*---------------------------------------------------------------------------*
* OP0001: MOVE.B
*---------------------------------------------------------------------------*
OP0001      
            JMP     OP_MOVE_B   * display MOVE.B
            
*---------------------------------------------------------------------------*
* OP_MOVE_B: display MOVE_B and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVE_B                                                                       
           
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'V',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            
            BSR     GET_EA_EA_SRC
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            
            RTS
            
           
*---------------------------------------------------------------------------*
* OP0010: decode MOVE.L/MOVEA.L
*---------------------------------------------------------------------------*
OP0010      
            MOVE.B  #2,D4
            CLR.L   D0                     
            CLR.L   D1                      
            MOVEA.L #0, A1                 
            
            MOVE.L  D5,D1
            ROR.L   #5,D1
            ANDI.L  #$E,D1
            CMPI.B  #2,D1
            BEQ     OP_MOVEA_L

            JMP     OP_MOVE_L
           

*---------------------------------------------------------------------------*
* OP_MOVE_L: display MOVE_L and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVE_L   
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'V',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            BSR     GET_EA_EA_SRC
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            
            RTS


*---------------------------------------------------------------------------*
* OP_MOVEA_L: display MOVEA_L and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVEA_L 
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$FD,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'V',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK           
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            BSR     GET_EA_EA_SRC
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            
            RTS

            
*---------------------------------------------------------------------------*
* OP0011: decode MOVE.W/MOVEA.W
*---------------------------------------------------------------------------*
OP0011      
            CLR.L   D0                      
            CLR.L   D1  
            CLR.L   D4                   
            MOVEA.L #0, A1 
              
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$07,D1
            CMPI.B  #1,D1
            BEQ     OP_MOVEA_W
            
            JMP     OP_MOVE_W
          
*---------------------------------------------------------------------------*
* OP_MOVE_W: display MOVE_W and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVE_W   
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'V',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            
            BSR     GET_EA_EA_SRC
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            
            RTS

*---------------------------------------------------------------------------*
* OP_MOVEA_W: display MOVEA and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVEA_W 
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$FD,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'V',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK           
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            
            BSR     GET_EA_EA_SRC
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
          
            RTS
*---------------------------------------------------------------------------*
* OP0100: decode MOVEM/LEA/NEG/JSR/RTS/NOT
*---------------------------------------------------------------------------*
OP0100
            CLR.L   D0                      
            CLR.L   D1  
            CLR.L   D4                      
            MOVEA.L #0, A1                  
            MOVE.L  D5,D1  
            
            * check for RTS
            CMPI.W  #$4E75,D1   * 0100 1110 0111 0101
            BEQ     OP_RTS
            
            * check for JSR     * 0100 1110 10 xxx (ea mode) xxx (ea reg)
            CLR.L   D1 
            MOVE.L  D5,D1  
            ANDI.W  #$0F00,D1
            CMPI.W  #$0E00,D1
            BEQ     OP_JSR

            * check for NEG     * 0100 0100 xx (size) xxx (ea mode) xxx (ea reg) 
            CLR.L   D1 
            MOVE.L  D5,D1  
            ANDI.W  #$0F00,D1
            CMPI.W  #$0400,D1
            BEQ     OP_NEG
            
            * check for NOT     * 0100 0110 xx (size) xxx (ea mode) xxx (ea reg)
            CLR.L   D1 
            MOVE.L  D5,D1  
            ANDI.W  #$0F00,D1
            CMPI.W  #$0600,D1
            BEQ     OP_NOT
            
            * check for LEA     * 0100 xxx (reg) 111 xxx (ea mode) xxx (ea reg)
            CLR.L   D1 
            MOVE.L  D5,D1  
            ROR.L   #6,D1
            ANDI.L  #7,D1
            CMPI.L  #7,D1
            BEQ     OP_LEA
            
            * check for MOVEM   * 0100 1 x 001 x (size) xxx (ea mode) xxx (ea reg)
            CLR.L   D1 
            MOVE.L  D5,D1  
            ROL.W   #5,D1
            CMPI.B  #1,D1
            BNE     OP_DATA
            ROL.W   #4,D1
            CMPI.B  #1,D1
            BNE     OP_DATA
            ROL.W   #1,D1
            CMPI.B  #0,D1
            BEQ     OP_MOVEM_W
            CMPI.B  #1,D1
            BEQ     OP_MOVEM_L
            JMP     OP_DATA

*---------------------------------------------------------------------------*
* OP_MOVEM_W: display MOVEM_W
*---------------------------------------------------------------------------*    
OP_MOVEM_W  
            MOVE.B  #1,D4
            LEA     DISP_MOVEM_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS

*---------------------------------------------------------------------------*
* OP_MOVEM_L: display MOVEM_L
*---------------------------------------------------------------------------*
OP_MOVEM_L  
            MOVE.B  #2,D4
            LEA     DISP_MOVEM_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
   
*---------------------------------------------------------------------------*
* OP_LEA: decode and display LEA
*---------------------------------------------------------------------------*
OP_LEA      
             CLR.L   D1       
            CLR.L   D4                   
            MOVEA.L #0, A1              
            MOVE.L  D5,D1       *DATA TO BE PROCESS IN [D1], TRY TO GET OPMODE AND DETERMINE .B/.W/.L
            *CLEAR D3
            CLR.L   D3

OP_LEA_DN_EA_OR_EA_DN 
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]      
        

OP_PRINT_L_LEA
                        
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$9B,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK           
            BSR     GET_EA_EA_DEST       *GETS Dn    

            
            BRA     OP_LEA_RETURN
            
OP_LEA_RETURN
            RTS
            


*---------------------------------------------------------------------------*
* OP_NEG: decode and display NEG 
*---------------------------------------------------------------------------*
OP_NEG      * 0100 0100 xx (size) xxx (ea mode) xxx (ea reg) 
            CLR.L   D1
            CLR.L   D4
            MOVE.L  D5,D1
            
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'N',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #'G',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            ANDI.L  #$07,D1
            
            CMPI.B  #0,D1
            BEQ     OP_NEG_B    * size is byte
            CMPI.B  #1,D1
            BEQ     OP_NEG_W    * size is word
            CMPI.B  #2,D1
            BEQ     OP_NEG_L    * size is long
                       

OP_NEG_B    * size is byte   
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            BRA     OP_NEG_PRINT_EA

            
OP_NEG_W    * size is word
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            BRA     OP_NEG_PRINT_EA

            
OP_NEG_L    * size is long
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            BRA     OP_NEG_PRINT_EA


OP_NEG_PRINT_EA
 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END
                       

            BSR     GET_EA_EA_SRC
            
            RTS

*---------------------------------------------------------------------------*
* OP_NOT: decode and display NOT 
*---------------------------------------------------------------------------*
OP_NOT
            CLR.L   D1
            CLR.L   D4
            MOVE.L  D5,D1
            
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'N',D3
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'T',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            ANDI.L  #$07,D1
            
            CMPI.B  #0,D1
            BEQ     OP_NOT_B    * size is byte
            CMPI.B  #1,D1
            BEQ     OP_NOT_W    * size is word
            CMPI.B  #2,D1
            BEQ     OP_NOT_L    * size is long
                       

OP_NOT_B    * size is byte   
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            BRA     OP_NOT_PRINT_EA

            
OP_NOT_W    * size is word
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            BRA     OP_NOT_PRINT_EA

            
OP_NOT_L    * size is long
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            BRA     OP_NOT_PRINT_EA


OP_NOT_PRINT_EA
 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END
            BSR     GET_EA_EA_SRC
            
            RTS


*---------------------------------------------------------------------------*
* OP_JSR: display JSR     
*---------------------------------------------------------------------------*
OP_JSR      LEA     DISP_JSR,A1
            MOVE.B  #14,D0
            TRAP    #15
            JSR     EA_NOSRC

            RTS

*---------------------------------------------------------------------------*
* OP_RTS: display RTS     
*---------------------------------------------------------------------------* 
OP_RTS      
            MOVE.B #'R',D3
            BSR     PUSH_STACK
            MOVE.B #'T',D3
            BSR     PUSH_STACK
            MOVE.B #'S',D3
            BSR     PUSH_STACK
            RTS

*---------------------------------------------------------------------------*
* OP0101: decode ADDQ
*---------------------------------------------------------------------------* 
OP0101      
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,DEST_REGISTER_FORMAT
           MOVE.B   #$80,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'Q',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            *FIGURE OUT SIZE*
            *00 = BYTE
            *01 = WORD
            *10 = LONG
            * BITS 7&6
            
            *COMPARE TO SEE IF IT IS BYTE/WORD/LONG SIZE
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.B  #%00,D1
            BEQ     OP0101_ADDQ_B
            ANDI.L  #$03,D1
            CMPI.B  #%01,D1
            BEQ     OP0101_ADDQ_W
            ANDI.L  #$03,D1
            CMPI.B  #%10,D1
            BEQ     OP0101_ADDQ_L
          
OP0101_ADDQ_B
            
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN
OP0101_ADDQ_W
            
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN
OP0101_ADDQ_L
            
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
OP0101_RETURN            

            
*GET DATA FROM ADDQ AND PRINT #0-8
            MOVE.B  #' ',D3
            BSR     PUSH_STACK
            MOVE.B  #'#',D3
            BSR     PUSH_STACK 

                     
            *GET DATA #   
            MOVE.L  D5,D1
            ROR.L   #6,D1            
            ROR.L   #3,D1
            ANDI.L  #$07,D1
            
            CMPI.B  #%000,D1
            BEQ     OP0101_ADDQ_B_8
            CMPI.B  #%001,D1
            BEQ     OP0101_ADDQ_B_1
            CMPI.B  #%010,D1
            BEQ     OP0101_ADDQ_B_2
            CMPI.B  #%011,D1
            BEQ     OP0101_ADDQ_B_3
            CMPI.B  #%100,D1
            BEQ     OP0101_ADDQ_B_4
            CMPI.B  #%101,D1
            BEQ     OP0101_ADDQ_B_5
            CMPI.B  #%110,D1
            BEQ     OP0101_ADDQ_B_6
            CMPI.B  #%111,D1
            BEQ     OP0101_ADDQ_B_7
            
OP0101_ADDQ_B_0
            MOVE.B  #'0',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN2            
OP0101_ADDQ_B_1
            MOVE.B  #'1',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN2            
OP0101_ADDQ_B_2
            MOVE.B  #'2',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN2            
OP0101_ADDQ_B_3
            MOVE.B  #'3',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN2            
OP0101_ADDQ_B_4
            MOVE.B  #'4',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN2            
OP0101_ADDQ_B_5
            MOVE.B  #'5',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN2
OP0101_ADDQ_B_6
            MOVE.B  #'6',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN2
OP0101_ADDQ_B_7
            MOVE.B  #'7',D3
            BSR     PUSH_STACK
            BRA     OP0101_RETURN2

OP0101_ADDQ_B_8
            MOVE.B  #'8',D3
            BSR     PUSH_STACK
            
OP0101_RETURN2            
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
            RTS


            
*---------------------------------------------------------------------------*
* OP_ADDQ: display ADDQ
*---------------------------------------------------------------------------*              
OP_ADDQ_B    * size is byte   
            MOVE.B  #0,D4 
            LEA     DISP_ADDQ_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_ADDQ_W    * size is word
            MOVE.B  #1,D4
            LEA     DISP_ADDQ_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_ADDQ_L    * size is long
            MOVE.B  #2,D4
            LEA     DISP_ADDQ_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS

*---------------------------------------------------------------------------*
* OP0110: decode BRA/BEQ/BNE/BLT/BHI
*---------------------------------------------------------------------------*              
OP0110  	CLR.L   D0                  
            CLR.L   D1   
            CLR.L   D4                 
            MOVEA.L #0,A1
            MOVE.L  D5, D1                
			ANDI.L  #$00FF, D1              * Get 8-bit displacement 
			MOVE.L  D5,D1                  
			ANDI.L  #$0F00,D1
               
			CMPI.W	#$0000,D1				* Check for BRA
			BEQ		OP_BRA					
						
			CMPI.W	#$0D00,D1				* Check for BLT
			BEQ		OP_BLT		

            CMPI.W  #$0700,D1               * Check for BEQ
            BEQ     OP_BEQ		

            CMPI.W  #$0600,D1               * Check for BNE
            BEQ     OP_BNE	
            
            CMPI.W  #$0200,D1               * Check for BHI
            BEQ     OP_BHI

            JMP 	OP_DATA
            
OP_BHI		MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'H',D3
            BSR     PUSH_STACK
            MOVE.B  #'I',D3
            BSR     PUSH_STACK
            MOVE.B  #$9,D3
            BSR     PUSH_STACK
            BSR     GET_DISPLACEMENT_ADDRESS
            RTS

OP_BNE		MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'N',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #$9,D3
            BSR     PUSH_STACK
            BSR     GET_DISPLACEMENT_ADDRESS
            RTS

OP_BEQ		MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #'Q',D3
            BSR     PUSH_STACK
            MOVE.B  #$9,D3
            BSR     PUSH_STACK
            BSR     GET_DISPLACEMENT_ADDRESS
            RTS          
            			
OP_BRA		
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'R',D3
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #$9,D3
            BSR     PUSH_STACK
            BSR     GET_DISPLACEMENT_ADDRESS
            
            RTS
            
OP_BLT		MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            MOVE.B  #'T',D3
            BSR     PUSH_STACK
            MOVE.B  #$9,D3
            BSR     PUSH_STACK
            BSR     GET_DISPLACEMENT_ADDRESS
            RTS
   
*---------------------------------------------------------------------------*
* OP0111 : MOVEQ not required
*---------------------------------------------------------------------------*           
OP0111      JMP     OP_DATA
           
*---------------------------------------------------------------------------*
* OP1000 : decode DIVS
*---------------------------------------------------------------------------*           
OP1000                           
            CLR.L   D1       
            CLR.L   D4                   
            MOVEA.L #0, A1              
            MOVE.L  D5,D1       *DATA TO BE PROCESS IN [D1], TRY TO GET OPMODE AND DETERMINE .B/.W/.L
            *CLEAR D3
            CLR.L   D3

OP1000_DIVS_DN_EA_OR_EA_DN 
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'I',D3
            BSR     PUSH_STACK
            MOVE.B  #'V',D3
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]      
            
OP1000_EA_DN_DIVS
            *BITS (7 TO 6) 
            *00 = .B
            *01 = .W
            *10 = .L 
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]  
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.L  #%11,D1 *EQUALS .W
            BEQ     OP1000_PRINT_W_DIVS
            CMPI.L  #%00,D1 *EQUALS .L
            BEQ     OP1000_PRINT_L_DIVS
            
            MOVE.B  #1,D4               *ERROR READ
            BRA     OP1000_DIVS_RETURN
OP1000_PRINT_W_DIVS
            MOVE.B  #'W',D3
            BSR     PUSH_STACK

            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

            
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST       *GETS Dn    
            
            BRA     OP1000_DIVS_RETURN
OP1000_PRINT_L_DIVS
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

                   
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                  
            BSR     GET_EA_EA_DEST       *GETS Dn    

            
            BRA     OP1000_DIVS_RETURN
            
OP1000_DIVS_RETURN
            RTS
            


*---------------------------------------------------------------------------*
* OP_DIVS: display DIVS and proceed to EA
*---------------------------------------------------------------------------*  
OP_DIVS     LEA     DISP_DIVS,A1
            MOVE.B  #14,D0
            TRAP    #15
            JMP     EA_ARITH

            RTS
            
*---------------------------------------------------------------------------*
* OP1001: decode SUB/SUBA
*---------------------------------------------------------------------------*      
OP1001      
            CLR.L   D0                  
            CLR.L   D1       
            CLR.L   D4                   
            MOVEA.L #0, A1              
            MOVE.L  D5,D1       *DATA TO BE PROCESS IN [D1], TRY TO GET OPMODE AND DETERMINE .B/.W/.L
            
            *CLEAR D3
            CLR.L   D3
            
            
            
            **INTEGRATING SUB.W/.L INTO THIS CODE**
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]      
            *BITS (INDEX 8) 
            *0 = ADD.B/W/L <EA>,Dn
            *1 = ADD.B/W/L Dn,<EA> 
            ROR.L   #6,D1
            ANDI.L  #$07,D1                 *MASKS WITH 00000111
            CMPI.L  #$07,D1                 *IF EQUALS <ea>,Dn
            BEQ     OP1001_SUBA_L            *BRANCHES TO ADDA.L
            CMPI.L  #$03,D1                 *IF EQUALS <ea>,Dn
            BEQ     OP1001_SUBA_W           *BRANCHES TO ADDA.W
            BRA     OP1001_DETERMINE_DN_EA_OR_EA_DN         *ELSE CHECK ADD.B/.W/.L
            
OP1001_SUBA_L
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            MOVE.B  #'U',D3
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
           MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 
     
            *PRINT <EA>,AN
            BSR     GET_EA_EA_SRC       *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                     
            BSR     GET_EA_EA_DEST      *GETS Dn

            
            
            RTS
OP1001_SUBA_W
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            MOVE.B  #'U',D3
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
           MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 
     
            *PRINT <EA>,AN
            BSR     GET_EA_EA_SRC       *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                     
            BSR     GET_EA_EA_DEST      *GETS Dn

            RTS

OP1001_DETERMINE_DN_EA_OR_EA_DN 
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            MOVE.B  #'U',D3
            BSR     PUSH_STACK
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]      
            
            *BITS (INDEX 8) 
            *0 = ADD.B/W/L <EA>,Dn
            *1 = ADD.B/W/L Dn,<EA> 
            ROR.L   #8,D1
            ANDI.L  #$01,D1     *MASKS WITH 00000001
            CMPI.L  #$00,D1     *IF EQUALS <ea>,Dn
            BEQ     OP1001_EA_DN
            *else procede to Dn_EA
            
OP1001_DN_EA
            *BITS (7 TO 6) 
            *00 = .B
            *01 = .W
            *10 = .L 
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]  
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.L  #$00,D1 *EQUALS .B
            BEQ     OP1001_PRINT_B2
            CMPI.L  #$01,D1 *EQUALS .W
            BEQ     OP1001_PRINT_W2
            CMPI.L  #$02,D1 *EQUALS .L
            BEQ     OP1001_PRINT_L2
OP1001_PRINT_B2
            *PUSH 'B'
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
           
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
           MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 
     
            BSR     GET_EA_EA_DEST      *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK                     
            BSR     GET_EA_EA_SRC       *GETS <ea>

            
            BRA     OP1101_ADD_RETURN
OP1001_PRINT_W2
            MOVE.B  #'W',D3
            BSR     PUSH_STACK

            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A An Register (001) 

      
            BSR     GET_EA_EA_DEST      *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK               
            BSR     GET_EA_EA_SRC       *GETS <ea>       



            BRA     OP1101_ADD_RETURN
OP1001_PRINT_L2 
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 

             
            BSR     GET_EA_EA_DEST       *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK          
            BSR     GET_EA_EA_SRC        *GETS <ea>

            BRA     OP1101_ADD_RETURN
            
OP1001_EA_DN           
            *BITS (7 TO 6) 
            *00 = .B
            *01 = .W
            *10 = .L 
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]  
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.L  #$00,D1 *EQUALS .B
            BEQ     OP1001_PRINT_B
            CMPI.L  #$01,D1 *EQUALS .W
            BEQ     OP1001_PRINT_W
            CMPI.L  #$02,D1 *EQUALS .L
            BEQ     OP1001_PRINT_L
OP1001_PRINT_B
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
              
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$02,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "AN" Register (001) 

            
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK          
            BSR     GET_EA_EA_DEST       *GETS Dn
            
            BRA     OP1101_ADD_RETURN
OP1001_PRINT_W
            MOVE.B  #'W',D3
            BSR     PUSH_STACK

            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 

            
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST       *GETS Dn    
            
            BRA     OP1001_ADD_RETURN
OP1001_PRINT_L 
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 

                   
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                  
            BSR     GET_EA_EA_DEST       *GETS Dn    

            
            BRA     OP1001_ADD_RETURN
            
OP1001_ADD_RETURN
            RTS

  
*---------------------------------------------------------------------------*
* OP_SUB: display SUB and proceed to EA
*---------------------------------------------------------------------------*            
OP_SUB_B    LEA     DISP_SUB_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            JMP     EA_GEN

            RTS

OP_SUB_W    LEA     DISP_SUB_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            JMP     EA_GEN

            RTS

OP_SUB_L    LEA     DISP_SUB_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            JMP     EA_GEN

            RTS

*---------------------------------------------------------------------------*
* OP_SUBA: display SUBA
*---------------------------------------------------------------------------*  
OP_SUBA_W   LEA     DISP_SUBA_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS

OP_SUBA_L   LEA     DISP_SUBA_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS         
*---------------------------------------------------------------------------*
* OP1010 : unassigned
*---------------------------------------------------------------------------*           
OP1010      JMP     OP_DATA
            
*---------------------------------------------------------------------------*
* OP1011 : decode CMP/EOR/CMPA
*---------------------------------------------------------------------------*           
OP1011      CLR.L   D0                
            CLR.L   D1            
            CLR.L   D4                   
            MOVEA.L #0, A1               
            MOVE.L  D5,D1
            ROR.L   #5,D1
            ANDI.L  #$E,D1
            CMPI.B  #$0,D1
            BEQ     OP1011_CMP
            CMPI.B  #$2,D1
            BEQ     OP1011_CMP
            CMPI.B  #$4,D1
            BEQ     OP1011_CMP
            CMPI.B  #$8,D1
            BEQ     OP1011_EOR
            CMPI.B  #$A,D1
            BEQ     OP1011_EOR
            CMPI.B  #$C,D1
            BEQ     OP1011_EOR  
            CMPI.B  #$6,D1
            BEQ     OP1011_CMPA
            CMPI.B  #$E,D1
            BEQ     OP1011_CMPA 

            JMP     OP_DATA          




OP1011_CMP
           
 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'C',D3
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'P',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            *FIGURE OUT SIZE*
            *00 = BYTE
            *01 = WORD
            *10 = LONG
            * BITS 7&6
            
            *COMPARE TO SEE IF IT IS BYTE/WORD/LONG SIZE
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.B  #%00,D1
            BEQ     OP1011_CMP_B
            ANDI.L  #$03,D1
            CMPI.B  #%01,D1
            BEQ     OP1011_CMP_W
            ANDI.L  #$03,D1
            CMPI.B  #%10,D1
            BEQ     OP1011_CMP_L
          
OP1011_CMP_B
            
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            BRA     OP1011_RETURN_CMP  
OP1011_CMP_W
            
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            BRA     OP1011_RETURN_CMP  
OP1011_CMP_L
            
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
OP1011_RETURN_CMP            

            
*GET DATA FROM ADDQ AND PRINT #0-8
     
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

            BSR     GET_EA_EA_SRC
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            
            RTS
            


OP1011_CMPA
            
 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$80,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'C',D3
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'P',D3
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            *FIGURE OUT SIZE*
            *00 = BYTE
            *01 = WORD
            *10 = LONG
            * BITS 7&6
            
            *COMPARE TO SEE IF IT IS BYTE/WORD/LONG SIZE
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.B  #%01,D1
            BEQ     OP1011_CMPA_W
            ANDI.L  #$03,D1
            CMPI.B  #%10,D1
            BEQ     OP1011_CMPA_L
OP1011_CMPA_W
            
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            BRA     OP1011_RETURN_CMPA 
OP1011_CMPA_L
            
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
OP1011_RETURN_CMPA            

            
*GET DATA FROM ADDQ AND PRINT #0-8
     
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0040,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (000) 

            BSR     GET_EA_EA_SRC
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST
            
            RTS

OP1011_EOR

 *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,DEST_REGISTER_FORMAT
           MOVE.B   #$80,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
            *CLEAR D3
            CLR.L   D3
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'E',D3
            BSR     PUSH_STACK
            MOVE.B  #'O',D3
            BSR     PUSH_STACK
            MOVE.B  #'R',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            *FIGURE OUT SIZE*
            *00 = BYTE
            *01 = WORD
            *10 = LONG
            * BITS 7&6
            
            *COMPARE TO SEE IF IT IS BYTE/WORD/LONG SIZE
            MOVE.L  D5,D1
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.B  #%00,D1
            BEQ     OP1011_EOR_B
            ANDI.L  #$03,D1
            CMPI.B  #%01,D1
            BEQ     OP1011_EOR_W
            ANDI.L  #$03,D1
            CMPI.B  #%10,D1
            BEQ     OP1011_EOR_L
          
OP1011_EOR_B
            
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            BRA     OP1011_RETURN
OP1011_EOR_W
            
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            BRA     OP1011_RETURN
OP1011_EOR_L
            
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
OP1011_RETURN            

            
*GET DATA FROM ADDQ AND PRINT #0-8
     
            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

            BSR     GET_EA_EA_DEST
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
            RTS
            
            
            
            

*---------------------------------------------------------------------------*
* OP_CMPA: display CMPA 
*---------------------------------------------------------------------------
OP_CMPA_W   LEA     DISP_CMPA_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS

OP_CMPA_L   LEA     DISP_CMPA_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS

*---------------------------------------------------------------------------*
* OP_CMP: display CMP and proceed to EA
*---------------------------------------------------------------------------*  
OP_CMP_B    LEA     DISP_CMP_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            JMP     EA_GEN

            RTS
            
OP_CMP_W    LEA     DISP_CMP_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            JMP     EA_GEN

            RTS
            
OP_CMP_L    LEA     DISP_CMP_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            JMP     EA_GEN

            RTS
            
*---------------------------------------------------------------------------*
* OP_EOR: display EOR
*---------------------------------------------------------------------------*  
OP_EOR_B    LEA     DISP_EOR_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            RTS
            
OP_EOR_W    LEA     DISP_EOR_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS
            
OP_EOR_L    LEA     DISP_EOR_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS    

*---------------------------------------------------------------------------*
* OP1100: Decode and display MULS/AND and proceed to EA
*---------------------------------------------------------------------------* 
OP1100      CLR.L   D0                 
            CLR.L   D1    
            CLR.L   D4                
            MOVEA.L #0, A1        
            MOVE.L  D5,D1
            LSR.L   #5,D1
            ANDI.L  #$E,D1
            CMPI.W  #$E,D1
            BEQ     OP_MULS
            BRA     OP1100_DETERMINE_DN_EA_OR_EA_DN 

OP_MULS                      
            CLR.L   D1       
            CLR.L   D4                   
            MOVEA.L #0, A1              
            MOVE.L  D5,D1       *DATA TO BE PROCESS IN [D1], TRY TO GET OPMODE AND DETERMINE .B/.W/.L
            *CLEAR D3
            CLR.L   D3

OP1100_MULS_DN_EA_OR_EA_DN 
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'M',D3
            BSR     PUSH_STACK
            MOVE.B  #'U',D3
            BSR     PUSH_STACK
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]      
            
OP1100_EA_DN_MULS           
            *BITS (7 TO 6) 
            *00 = .B
            *01 = .W
            *10 = .L 
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]  
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.L  #%11,D1 *EQUALS .W
            BEQ     OP1100_PRINT_W_MULS
            CMPI.L  #%00,D1 *EQUALS .L
            BEQ     OP1100_PRINT_L_MULS
            
            MOVE.B  #1,D4               *ERROR READ
            BRA     OP1100_MULS_RETURN
OP1100_PRINT_W_MULS
            MOVE.B  #'W',D3
            BSR     PUSH_STACK

            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

            
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST       *GETS Dn    
            
            BRA     OP1100_MULS_RETURN
OP1100_PRINT_L_MULS 
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

                   
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                  
            BSR     GET_EA_EA_DEST       *GETS Dn    

            
            BRA     OP1100_MULS_RETURN
            
OP1100_MULS_RETURN
            RTS
            












OP1100_DETERMINE_DN_EA_OR_EA_DN 
            *LOAD STACK WITH THIS OPMODE
            CLR.L   D3
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'N',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]      
            
            *BITS (INDEX 8) 
            *0 = ADD.B/W/L <EA>,Dn
            *1 = ADD.B/W/L Dn,<EA> 
            ROR.L   #8,D1
            ANDI.L  #$01,D1     *MASKS WITH 00000001
            CMPI.L  #$00,D1     *IF EQUALS <ea>,Dn
            BEQ     OP1100_EA_DN
            *else procede to Dn_EA
            
OP1100_DN_EA
            *BITS (7 TO 6) 
            *00 = .B
            *01 = .W
            *10 = .L 
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]  
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.L  #$00,D1 *EQUALS .B
            BEQ     OP1100_PRINT_B2
            CMPI.L  #$01,D1 *EQUALS .W
            BEQ     OP1100_PRINT_W2
            CMPI.L  #$02,D1 *EQUALS .L
            BEQ     OP1100_PRINT_L2
OP1100_PRINT_B2
            *PUSH 'B'
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
           
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
           MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000000000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 
     
            BSR     GET_EA_EA_DEST      *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK                     
            BSR     GET_EA_EA_SRC       *GETS <ea>

            
            BRA     OP1100_AND_RETURN
OP1100_PRINT_W2
            MOVE.B  #'W',D3
            BSR     PUSH_STACK

            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000000000000,D5   *Add.B  BITS 8-6 TO INDICATE A An Register (001) 

      
            BSR     GET_EA_EA_DEST      *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK               
            BSR     GET_EA_EA_SRC       *GETS <ea>       



            BRA     OP1101_ADD_RETURN
OP1100_PRINT_L2 
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000000000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 

             
            BSR     GET_EA_EA_DEST       *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK          
            BSR     GET_EA_EA_SRC        *GETS <ea>

            BRA     OP1100_AND_RETURN
            
OP1100_EA_DN           
            *BITS (7 TO 6) 
            *00 = .B
            *01 = .W
            *10 = .L 
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]  
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.L  #$00,D1 *EQUALS .B
            BEQ     OP1100_PRINT_B
            CMPI.L  #$01,D1 *EQUALS .W
            BEQ     OP1100_PRINT_W
            CMPI.L  #$02,D1 *EQUALS .L
            BEQ     OP1100_PRINT_L
OP1100_PRINT_B
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
              
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$02,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000000000000,D5   *Add.B  BITS 8-6 TO INDICATE A "AN" Register (001) 

            
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK          
            BSR     GET_EA_EA_DEST       *GETS Dn
            
            BRA     OP1101_ADD_RETURN
OP1100_PRINT_W
            MOVE.B  #'W',D3
            BSR     PUSH_STACK

            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$02,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000000000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 

            
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST       *GETS Dn    
            
            BRA     OP1001_ADD_RETURN
OP1100_PRINT_L 
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$02,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000000000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 

                   
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                  
            BSR     GET_EA_EA_DEST       *GETS Dn    

            
            BRA     OP1100_AND_RETURN
            
OP1100_AND_RETURN
            RTS


*---------------------------------------------------------------------------*
* OP1101: Decode ADD/ADDA
*---------------------------------------------------------------------------* 
OP1101      CLR.L   D0                  
            CLR.L   D1       
            CLR.L   D4                   
            MOVEA.L #0, A1              
            MOVE.L  D5,D1       *DATA TO BE PROCESS IN [D1], TRY TO GET OPMODE AND DETERMINE .B/.W/.L
            
            *CLEAR D3
            CLR.L   D3
            
            
            
            **INTEGRATING ADDA.W/.L INTO THIS CODE**
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]      
            *BITS (INDEX 8) 
            *0 = ADD.B/W/L <EA>,Dn
            *1 = ADD.B/W/L Dn,<EA> 
            ROR.L   #6,D1
            ANDI.L  #$07,D1                 *MASKS WITH 00000111
            CMPI.L  #$07,D1                 *IF EQUALS <ea>,Dn
            BEQ     OP1101_ADDA_L            *BRANCHES TO ADDA.L
            CMPI.L  #$03,D1                 *IF EQUALS <ea>,Dn
            BEQ     OP1101_ADDA_W           *BRANCHES TO ADDA.W
            BRA     OP1101_DETERMINE_DN_EA_OR_EA_DN         *ELSE CHECK ADD.B/.W/.L
            
OP1101_ADDA_L
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
           MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 
     
            *PRINT <EA>,AN
            BSR     GET_EA_EA_SRC       *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                     
            BSR     GET_EA_EA_DEST      *GETS Dn

            
            
            RTS
OP1101_ADDA_W
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
           MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #%0000000001000000,D5   *Add.B  BITS 8-6 TO INDICATE A "An" Register (001) 
     
            *PRINT <EA>,AN
            BSR     GET_EA_EA_SRC       *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                     
            BSR     GET_EA_EA_DEST      *GETS Dn

            RTS

OP1101_DETERMINE_DN_EA_OR_EA_DN 
            *LOAD STACK WITH THIS OPMODE
            BSR     PUSH_STACK
            MOVE.B  #'A',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'D',D3
            BSR     PUSH_STACK
            MOVE.B  #'.',D3
            BSR     PUSH_STACK
            
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]      
            
            *BITS (INDEX 8) 
            *0 = ADD.B/W/L <EA>,Dn
            *1 = ADD.B/W/L Dn,<EA> 
            ROR.L   #8,D1
            ANDI.L  #$01,D1     *MASKS WITH 00000001
            CMPI.L  #$00,D1     *IF EQUALS <ea>,Dn
            BEQ     OP1101_EA_DN
            *else procede to Dn_EA
            
OP1101_DN_EA
            *BITS (7 TO 6) 
            *00 = .B
            *01 = .W
            *10 = .L 
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]  
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.L  #$00,D1 *EQUALS .B
            BEQ     OP1101_PRINT_B2
            CMPI.L  #$01,D1 *EQUALS .W
            BEQ     OP1101_PRINT_W2
            CMPI.L  #$02,D1 *EQUALS .L
            BEQ     OP1101_PRINT_L2
OP1101_PRINT_B2
            *PUSH 'B'
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
           
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$02,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
           MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
           MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 
     
            BSR     GET_EA_EA_DEST      *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK                     
            BSR     GET_EA_EA_SRC       *GETS <ea>

            
            BRA     OP1101_ADD_RETURN
OP1101_PRINT_W2
            MOVE.B  #'W',D3
            BSR     PUSH_STACK

            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

      
            BSR     GET_EA_EA_DEST      *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK               
            BSR     GET_EA_EA_SRC       *GETS <ea>       



            BRA     OP1101_ADD_RETURN
OP1101_PRINT_L2 
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$83,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

             
            BSR     GET_EA_EA_DEST       *GETS Dn
            MOVE.B  #',',D3
            BSR     PUSH_STACK          
            BSR     GET_EA_EA_SRC        *GETS <ea>

            BRA     OP1101_ADD_RETURN
            
OP1101_EA_DN           
            *BITS (7 TO 6) 
            *00 = .B
            *01 = .W
            *10 = .L 
            MOVE.L  D5,D1       *GET CLEAN COPY OF DATA INTO [D1]  
            ROR.L   #6,D1
            ANDI.L  #$03,D1
            CMPI.L  #$00,D1 *EQUALS .B
            BEQ     OP1101_PRINT_B
            CMPI.L  #$01,D1 *EQUALS .W
            BEQ     OP1101_PRINT_W
            CMPI.L  #$02,D1 *EQUALS .L
            BEQ     OP1101_PRINT_L
OP1101_PRINT_B
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
              
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$02,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$02,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

            
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK          
            BSR     GET_EA_EA_DEST       *GETS Dn
            
            BRA     OP1101_ADD_RETURN
OP1101_PRINT_W
            MOVE.B  #'W',D3
            BSR     PUSH_STACK

            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

           *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

            
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_DEST       *GETS Dn    
            
            BRA     OP1101_ADD_RETURN
OP1101_PRINT_L 
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            
            *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
            MOVE.B   #$00,DEST_REGISTER_FORMAT               *doesn't allow An in either dest or src formats
            MOVE.B   #$00,SRC_REGISTER_FORMAT                *THIS IS WHAT ARE THE POSSIBLE EA,EA
           
            *INITIALIZE WHERE TO FIND REGISTER NUMBERS
            MOVE.B   #$B9,GET_DST_START_END                  *THIS IS THE WHERE WE CAN FIND REGISTER NUMBERS
            MOVE.B   #$20,GET_SRC_START_END

            *CHANGE D5 SO THAT BITS 5-3(source mode) REFLECT  <Dn mode> for get_ea_ea format
            ANDI.L  #$FE3F,D5   *inverse mask bits 8-6 with 1111(F[15]) 1110(E[14]) 0011(3) 1111(F[15]), TO REPLACE OPMODE WITH DN-MODE
            ADDI.L  #$0000,D5   *Add.B  BITS 8-6 TO INDICATE A Dn Register (000) 

                   
            BSR     GET_EA_EA_SRC      *GETS <ea>
            MOVE.B  #',',D3
            BSR     PUSH_STACK                  
            BSR     GET_EA_EA_DEST       *GETS Dn    

            
            BRA     OP1101_ADD_RETURN
            
OP1101_ADD_RETURN
            RTS
            
            *ADDW
            CMPI.B  #$6,D1
            BEQ     OP_ADDA_W
            CMPI.B  #$E,D1
            BEQ     OP_ADDA_L 

            JMP     OP_DATA  
          
*---------------------------------------------------------------------------*
* OP_ADD: display ADD and proceed to EA
*---------------------------------------------------------------------------*  
OP_ADD_B    LEA     DISP_ADD_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            JMP     EA_GEN

            RTS

OP_ADD_W    LEA     DISP_ADD_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            JMP     EA_GEN

            RTS

OP_ADD_L    LEA     DISP_ADD_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            JMP     EA_GEN

            RTS

*---------------------------------------------------------------------------*
* OP_ADDA: display ADDA and proceed to EA
*---------------------------------------------------------------------------*  
OP_ADDA_W   LEA     DISP_ADDA_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            JMP     EA_GEN

            RTS

OP_ADDA_L   LEA     DISP_ADDA_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            JMP     EA_GEN

            RTS
            
*---------------------------------------------------------------------------*
* OP1110: LSR/LSL/ASR/ASL/ROL/ROR
*---------------------------------------------------------------------------* 
OP1110      CLR.L   D0                  
            CLR.L   D1   
            CLR.L   D4                   
            MOVEA.L #0, A1                 
            MOVE.L  D5,D1
            
            *1)CHECK FOR MEMORY ROTATE/SHIFT FIRST
            MOVE.L  D5,D1                   *RESET
            ANDI.L  #%1111111011000000,D1
            CMPI.L  #%1110000011000000,D1
            BEQ     OP_ASX                  *ASX

            
            ANDI.L  #%1111111011000000,D1
            CMPI.L  #%1110011011000000,D1
            BEQ     OP_ROX                  *ROX

            MOVE.L  D5,D1                   *RESET
            ANDI.L  #%1111111011000000,D1
            CMPI.L  #%1110001011000000,D1
            BEQ     OP_LSX                  *LSX

  
            *2) CHECK FOR REGISTER SHIFTS
            MOVE.L  D5,D1                   *RESET
            ANDI.L  #%1111000000011000,D1
            CMPI.L  #%1110000000001000,D1
            BEQ     OP_LSX                  *LSX

            
            MOVE.L  D5,D1                   *RESET
            ANDI.L  #%1111000000011000,D1
            CMPI.L  #%1110000000000000,D1
            BEQ     OP_ASX                  *ASX

            
            MOVE.L  D5,D1                   *RESET
            ANDI.L  #%1111000000011000,D1
            CMPI.L  #%1110000000011000,D1
            BEQ     OP_ROX                  *ROX


                        
OP1110_RETURN       
            RTS


*---------------------------------------------------------------------------*
* OP_LSR: decode and display LSR
*---------------------------------------------------------------------------*        
OP_LSX     
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            MOVE.B  #'S',D3
            BSR     PUSH_STACK
            
            *FIND IF ITS RIGHT OR LEFT DIR
            MOVE.L  D5,D1                   *RESET
            ANDI.L  #%0000000100000000,D1
            CMPI.L  #%0000000000000000,D1   * RIGHT CHECK
            BEQ     OP_LSX_R      
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_DIR
OP_LSX_R           
            MOVE.B  #'R',D3
            BSR     PUSH_STACK
            
OP_LSX_DIR
            MOVE.B  #'.',D3
            BSR     PUSH_STACK

            *FIND SIZE OF OPCODE
            MOVE.L  D5,D1                   *RESET
            ANDI.L  #%0000000011000000,D1
            CMPI.L  #%0000000010000000,D1            *L
            BEQ     OP_LSX_L
            CMPI.L  #%0000000001000000,D1            *W
            BEQ     OP_LSX_W  
            CMPI.L  #%0000000000000000,D1            *W
            BEQ     OP_LSX_B       
                                    *OTHERWISE B    
            
OP_LSX_L
            MOVE.B  #'L',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_CHECK_FORMAT 
OP_LSX_W
            MOVE.B  #'W',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_CHECK_FORMAT 
OP_LSX_B
            MOVE.B  #'B',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_CHECK_FORMAT 
                      
OP_LSX_CHECK_FORMAT              
            * CHECKS IF ITS A MEMORY SHIFT FORMAT
            MOVE.L  D5,D1                   *RESET
            ANDI.L  #%1111111011000000,D1
            CMPI.L  #%1110001011000000,D1
            BEQ     OP_LSX_MEMORY           
            
            *ELSE ITS REGISTER
OP_LSX_REGISTER
           *TODO
           *CHECK IF ITS INTERMEDIATE OR REGISTER
           MOVE.L  D5,D1                   *RESET
           ROR.L   #5,D1 
           ANDI.L  #1,D1
           CMPI.L  #0,D1                    * 1=DATA REGISTER 0= INTERMEDIATE(1-7)
           BEQ     OP_LSX_INTERMEDIATE
           *ELSE ITS DATA REGISTER

           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
           *SETS BOTH SRC/DEST MODES TO "Dn"
           ANDI.L   #%1111111000000111,D5
           ADDI.L   #%0000000000000000,D5
           
            *CLEAR D3
            CLR.L   D3
         
            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
            RTS

OP_LSX_INTERMEDIATE
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$82,DEST_REGISTER_FORMAT
           MOVE.B   #$00,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
           *SETS BOTH SRC/DEST MODES TO "Dn"
           ANDI.L   #%1111111000000111,D5
           ADDI.L   #%0000000000000000,D5
           
            *CLEAR D3
            CLR.L   D3
           
*-------------------------grabbing #immediate data-----------------------*

*GET DATA FROM ADDQ AND PRINT #0-8
            MOVE.B  #' ',D3
            BSR     PUSH_STACK
            MOVE.B  #'#',D3
            BSR     PUSH_STACK 

                     
            *GET DATA #   
            MOVE.L  D5,D1
            ROR.L   #6,D1            
            ROR.L   #3,D1
            ANDI.L  #$07,D1
            
            CMPI.B  #%000,D1
            BEQ     OP_LSX_0
            CMPI.B  #%001,D1
            BEQ     OP_LSX_1
            CMPI.B  #%010,D1
            BEQ     OP_LSX_2
            CMPI.B  #%011,D1
            BEQ     OP_LSX_3
            CMPI.B  #%100,D1
            BEQ     OP_LSX_4
            CMPI.B  #%101,D1
            BEQ     OP_LSX_5
            CMPI.B  #%110,D1
            BEQ     OP_LSX_6
            CMPI.B  #%111,D1
            BEQ     OP_LSX_7
            
OP_LSX_0
            MOVE.B  #'0',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_AFTER_IMMEDIATE            
OP_LSX_1
            MOVE.B  #'1',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_AFTER_IMMEDIATE            
OP_LSX_2
            MOVE.B  #'2',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_AFTER_IMMEDIATE            
OP_LSX_3
            MOVE.B  #'3',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_AFTER_IMMEDIATE            
OP_LSX_4
            MOVE.B  #'4',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_AFTER_IMMEDIATE           
OP_LSX_5
            MOVE.B  #'5',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_AFTER_IMMEDIATE
OP_LSX_6
            MOVE.B  #'6',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_AFTER_IMMEDIATE
OP_LSX_7
            MOVE.B  #'7',D3
            BSR     PUSH_STACK
            BRA     OP_LSX_AFTER_IMMEDIATE

OP_LSX_8
            MOVE.B  #'8',D3
            BSR     PUSH_STACK
            
OP_LSX_AFTER_IMMEDIATE            

*-------------------------grabbing #immediate data-----------------------*

            MOVE.B  #',',D3
            BSR     PUSH_STACK
            BSR     GET_EA_EA_SRC
            
            RTS

            BRA     OP_LSX_RETURN
            
            
OP_LSX_MEMORY
           *INITIALIZE EA FORMAT STANDARDS: IF AN,(AN),-(AN)...ETC COULD BE USED
           MOVE.B   #$83,SRC_REGISTER_FORMAT
           
           *INITIALIZE WHERE TO FIND REGISTER NUMBERS
           MOVE.B   #$B9,GET_DST_START_END
           MOVE.B   #$20,GET_SRC_START_END
           
           *pop previous thing out
           BSR      POP_STACK
           
           *print w
           MOVE.B  #'W',D3
           BSR     PUSH_STACK
           BSR     GET_EA_EA_SRC

OP_LSX_RETURN
            BRA     OP1110_RETURN  
            
*---------------------------------------------------------------------------*
* OP_LSR: decode and display LSR IMMEDIATE/REGISTER
*---------------------------------------------------------------------------*        
OP_ASX
            LEA     DISP_ASR_B,A1
            MOVE.B  #14,D0
            TRAP    #15

            BRA     OP1110_RETURN  
    
*---------------------------------------------------------------------------*
* OP_ROX: decode and display LSR IMMEDIATE/REGISTER
*---------------------------------------------------------------------------*        
OP_ROX

            LEA     DISP_ROR_B,A1
            MOVE.B  #14,D0
            TRAP    #15

            BRA     OP1110_RETURN  






















            
*---------------------------------------------------------------------------*
* OP1111 : Special reserved
*---------------------------------------------------------------------------*           
OP1111      JMP     OP_DATA

*---------------------------------------------------------------------------*
* EA_NOSRC: decode and display effective addresses for NEG/JSR
*---------------------------------------------------------------------------*
EA_NOSRC    
            JSR     SRC_MODE
            LEA     ENDLINE_M,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
*---------------------------------------------------------------------------*
* EA_ARITH: decode and display effective addresses for DIVS/MULS
*---------------------------------------------------------------------------*
EA_ARITH
            JSR     SRC_MODE
            LEA     DISP_D,A1
            MOVE.B  #14,D0
            TRAP    #15
            JSR     DEST_REGISTER
            LEA     ENDLINE_M,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
*---------------------------------------------------------------------------*
* EA_MOVEA: decode and display effective addresses for MOVEA/LEA
*---------------------------------------------------------------------------*
EA_MOVEA
            JSR     SRC_MODE
            LEA     DISP_AOP,A1
            MOVE.B  #14,D0
            TRAP    #15
            JSR     DEST_REGISTER
            LEA     DISP_CP,A1
            MOVE.B  #13,D0
            TRAP    #15
            RTS
            
*---------------------------------------------------------------------------*
* EA_GEN: decode and display effective addresses for MOVE
*---------------------------------------------------------------------------*
EA_GEN          
            * retrieve/display source mode/register
            JSR     SRC_MODE
            
            * retrieve/display destination mode/register
            JSR     DEST_MODE
            
            LEA     ENDLINE_M,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS

*---------------------------------------------------------------------------*
* DEST_MODE: decode and display destination mode (bit 8 - 6)
*---------------------------------------------------------------------------*           
DEST_MODE   
            * clear registers to store temp data
            CLR.L   D0                      
            CLR.L   D1                      
            MOVEA.L #0, A0                  
            MOVEA.L #0, A1                  
            MOVE.L  D5,D1
            LSR.L   #6,D1
            ANDI.L  #$7,D1
            CMPI.B  #0,D1   * Dn
            BEQ     D_MODE000
            CMPI.B  #2,D1   * (An)
            BEQ     D_MODE010
            CMPI.B  #3,D1   * (An)+
            BEQ     D_MODE011
            CMPI.B  #4,D1   * -(An)
            BEQ     D_MODE100
            CMPI.B  #7,D1  * abs
            BEQ     D_MODE111 
            RTS

*---------------------------------------------------------------------------*
* SRC_MODE: decode and display source mode (bit 5 - 3)
*---------------------------------------------------------------------------*  
SRC_MODE    
            * clear registers to store temp data
            CLR.L   D0                      
            CLR.L   D1                      
            MOVEA.L #0, A0                  
            MOVEA.L #0, A1                  
            MOVE.L  D5,D1
            LSR.L   #2,D1
            ANDI.L  #$E,D1
            
            CMPI.B  #0,D1   * Dn
            BEQ     MODE000
            CMPI.B  #2,D1   * An 
            BEQ     MODE001
            CMPI.B  #4,D1   * (An)
            BEQ     MODE010
            CMPI.B  #6,D1   * (An)+
            BEQ     MODE011
            CMPI.B  #8,D1   * -(An)
            BEQ     MODE100
            CMPI.B  #15,D1  * abs/immediate
            BEQ     MODE111 
      
*---------------------------------------------------------------------------*
* MODE000: decode and display source mode Dn
*---------------------------------------------------------------------------*           
MODE000     *Dn
            LEA     DISP_D,A1
            MOVE.B  #14,D0
            TRAP    #15
            JSR     SRC_REGISTER
            RTS

*---------------------------------------------------------------------------*
* D_MODE000: decode and display dest mode Dn
*---------------------------------------------------------------------------*
D_MODE000     *Dn
            LEA     DISP_D,A1
            MOVE.B  #14,D0
            TRAP    #15
            JSR     DEST_REGISTER
            RTS

*---------------------------------------------------------------------------*
* MODE001: decode and display source mode An
*---------------------------------------------------------------------------* 
MODE001 *An
            LEA     DISP_A,A1
            MOVE.B  #14,D0
            TRAP    #15
            JSR     SRC_REGISTER
        
            RTS

*---------------------------------------------------------------------------*
* MODE010: decode and display source mode (An)
*---------------------------------------------------------------------------*    
MODE010 *(An)
            LEA     DISP_AOP,A1  *display (A
            MOVE.B  #14,D0
            TRAP    #15

            JSR     SRC_REGISTER * display register

            LEA     DISP_CP,A1   *display )
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS

*---------------------------------------------------------------------------*
* D_MODE010: decode and display dest mode (An)
*---------------------------------------------------------------------------*
D_MODE010 *(An)
            LEA     DISP_AOP,A1  *display (A
            MOVE.B  #14,D0
            TRAP    #15
   
            JSR     DEST_REGISTER * display register

            LEA     DISP_CP,A1   *display )
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS

*---------------------------------------------------------------------------*
* MODE011: decode and display source mode (An)+
*---------------------------------------------------------------------------*
MODE011 *(An)+
            LEA     DISP_AOP,A1      *display (A
            MOVE.B  #14,D0
            TRAP    #15
            
            JSR     SRC_REGISTER    * display register

            LEA     DISP_POST,A1    *display )+
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS
            
*---------------------------------------------------------------------------*
* MODE100: decode and display source mode -(An)
*---------------------------------------------------------------------------*
MODE100 *-(An)
            LEA     DISP_PRE,A1    *display -(A
            MOVE.B  #14,D0
            TRAP    #15

            JSR     SRC_REGISTER    *display register

            LEA     DISP_CP,A1   *display )
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS

*---------------------------------------------------------------------------*
* D_MODE011: decode and display dest mode (An)+
*---------------------------------------------------------------------------*
D_MODE011 *(An)+
            LEA     DISP_AOP,A1      *display (A
            MOVE.B  #14,D0
            TRAP    #15

            JSR     DEST_REGISTER    * display register

            LEA     DISP_POST,A1    *display )+
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS
            
*---------------------------------------------------------------------------*
* D_MODE100: decode and display dest mode -(An)
*---------------------------------------------------------------------------*            
D_MODE100 *-(An)
            LEA     DISP_PRE,A1    *display -(A
            MOVE.B  #14,D0
            TRAP    #15
            
            JSR     DEST_REGISTER    *display register

            LEA     DISP_CP,A1   *display )
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS

*---------------------------------------------------------------------------*
* MODE111: decode and display source mode absolute/immediate
*---------------------------------------------------------------------------*
MODE111     * abs/immediate
            * clear registers to store temp data
            CLR.L   D0                      
            CLR.L   D1                      
            MOVEA.L #0, A0                  
            MOVEA.L #0, A1                  
            MOVE.L  D5,D1
            
            * retrieve source register for MODE 111
            LSL.L   #1,D1   * shift the bits to left by 1
            ANDI.L  #$E,D1  * mask the first 4 bits 
            CMPI.B  #0, D1  * if it's 0000, absolute word address
            BEQ     WORDMODE
            CMPI.B  #2, D1  * if it's 0010, absolute long address
            BEQ     LONGMODE
            CMPI.B  #8, D1  * if it's 1000, immediate data
            BEQ     IMMEDIATE
     
*---------------------------------------------------------------------------*
* D_MODE111: decode and display dest mode absolute/immediate
*---------------------------------------------------------------------------*           
D_MODE111   * abs
            * clear registers to store temp data
            CLR.L   D0                      
            CLR.L   D1                      
            MOVEA.L #0, A0                  
            MOVEA.L #0, A1                  
            MOVE.L  D5,D1
            
            * retrieve dest register for MODE 111
            LSR.L   #6,D1   * shift the bits to right by 6
            LSR.L   #3,D1   * shift the bits to right by extra 3
            ANDI.B  #1,D1   * mask the first 2 bits 
            CMPI.B  #0, D1  * if it's 000, absolute word address
            BEQ     WORDMODE
            CMPI.B  #1, D1  * if it's 001, absolute long address
            BEQ     LONGMODE
            *JSR     OP_DATA *not sure..
            RTS


*---------------------------------------------------------------------------*
* WORDMODE: absolute word address
*---------------------------------------------------------------------------*
WORDMODE    LEA     DISP_HEX,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            CLR.L   D5
            MOVE.W  (A5)+,D5
            
            LEA     TMPOUTPUT,A1
            MOVE.L  D5,D1
            MOVE.L  #4,D2       *move word size 4
            JSR     HEX2ASCII
            LEA     TMPOUTPUT,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS

*---------------------------------------------------------------------------*
* LONGMODE: absolute long address
*---------------------------------------------------------------------------*
LONGMODE    LEA     DISP_HEX,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            CLR.L   D5
            MOVE.L  (A5)+,D5
            
            LEA     TMPOUTPUT,A1
            MOVE.L  D5,D1
            MOVE.L  #8,D2           *move longword size 8
            JSR     HEX2ASCII
            LEA     TMPOUTPUT,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            RTS


*---------------------------------------------------------------------------*
* IMMEDIATE: immediate address
*---------------------------------------------------------------------------*
IMMEDIATE   LEA     DISP_LB,A1
            MOVE.B  #14,D0
            TRAP    #15
            LEA     DISP_HEX,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            * check for size
            CMPI.B  #0,D4
            BEQ     IMMD_B
            CMPI.B  #1,D4
            BEQ     IMMD_W
            CMPI.B  #2,D4
            BEQ     IMMD_L

IMMD_B
            CLR.L   D5
            MOVE.W  (A5)+,D5
            
            LEA     TMPOUTPUT,A1
            MOVE.L  D5,D1
            MOVE.L  #2,D2
            JSR     HEX2ASCII
            LEA     TMPOUTPUT,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
IMMD_W
            CLR.L   D5
            MOVE.W  (A5)+,D5
            
            LEA     TMPOUTPUT,A1
            MOVE.L  D5,D1
            MOVE.L  #4,D2
            JSR     HEX2ASCII
            LEA     TMPOUTPUT,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            

IMMD_L
            CLR.L   D5
            MOVE.W  (A5)+,D5
            
            LEA     TMPOUTPUT,A1
            MOVE.L  D5,D1
            MOVE.L  #8,D2
            JSR     HEX2ASCII
            LEA     TMPOUTPUT,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS


*---------------------------------------------------------------------------*
* DEST_REGISTER: decode and display destination register (bit 11 - 9)
*---------------------------------------------------------------------------*
DEST_REGISTER
            * clear registers to store temp data
            CLR.L   D0                      
            CLR.L   D1                      
            MOVEA.L #0, A0                  
            MOVEA.L #0, A1 
            
            MOVE.L  D5,D1
            LSR.L   #6,D1
            LSR.L   #3,D1
            ANDI.L  #7,D1
            
            CMPI.B  #0,D1
            BEQ     REG_0
            CMPI.B  #1,D1
            BEQ     REG_1
            CMPI.B  #2,D1
            BEQ     REG_2
            CMPI.B  #3,D1
            BEQ     REG_3
            CMPI.B  #4,D1
            BEQ     REG_4
            CMPI.B  #5,D1
            BEQ     REG_5
            CMPI.B  #6,D1
            BEQ     REG_6
            CMPI.B  #7,D1
            BEQ     REG_7

*---------------------------------------------------------------------------*
* SRC_REGISTER: decode and display source register (bit 2 - 0)
*---------------------------------------------------------------------------*           
SRC_REGISTER 
            * clear registers to store temp data
            CLR.L   D0                      
            CLR.L   D1                      
            MOVEA.L #0, A0                  
            MOVEA.L #0, A1                  
            
            MOVE.L  D5,D1   * temp store the processing data
            ANDI.L  #7,D1   * mask the first 4 bits with 0111
            
            CMPI.B  #0,D1
            BEQ     REG_0
            CMPI.B  #1,D1
            BEQ     REG_1
            CMPI.B  #2,D1
            BEQ     REG_2
            CMPI.B  #3,D1
            BEQ     REG_3
            CMPI.B  #4,D1
            BEQ     REG_4
            CMPI.B  #5,D1
            BEQ     REG_5
            CMPI.B  #6,D1
            BEQ     REG_6
            CMPI.B  #7,D1
            BEQ     REG_7

*---------------------------------------------------------------------------*
* REG_0 ~ REG_7: display register 0 to 7
*---------------------------------------------------------------------------*
REG_0       LEA     DISP_0,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
REG_1       LEA     DISP_1,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            

REG_2       LEA     DISP_2,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
          
REG_3       LEA     DISP_3,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
REG_4       LEA     DISP_4,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
REG_5       LEA     DISP_5,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
REG_6       LEA     DISP_6,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
REG_7       LEA     DISP_7,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
*---------------------------------------------------------------------------*
* REPEAT : Ask user whether they wish to run the program again
*---------------------------------------------------------------------------*           
REPEAT      CLR.W   D6                      * Reset D6 (Loop Count)
            LEA     REPEATMSG,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            LEA     TMPINPUT,A1             * allocate space to temp store user input
            MOVE.B  #2,D0
            TRAP    #15

            CMPI.B  #1,D1                   * check for length of user input
            BNE     REPEAT                  * return to the beginning of the function if unequal
            
            CMPI.B  #$59,(A1)               * compare the input with Y    
            BEQ     PROGLP                  * repeat the program
            
            CMPI.B  #$79,(A1)               * compare the input with y    
            BEQ     PROGLP                  * repeat the program
            
            CMPI.B  #$4E,(A1)               * compare the input with N    
            BEQ     TERMINATE               * finish program
            
            CMPI.B  #$6E,(A1)               * compare the input with n    
            BEQ     TERMINATE               * finish program
            
            BRA     REPEAT                  * invalid input/repeat the function

*---------------------------------------------------------------------------*
* EA DECODING INTERFACE
* [A0] - RESERVED FOR USE
* [D2] - RESERVED FOR USE
* RETURNS - ERROR FLAG IF FAILED TO PUSH SRC EA INTO STACK
*---------------------------------------------------------------------------*
GET_EA_EA_SRC
    *PRECONDITION: 16 BIT DECODE DATA MUST BE IN REGISTER [D5]*
    
    *DETERMINE ADDRESS MODE OF EA WITH THE MODE CODE 
    MOVE.L  D5,D2                           * CLEAN COPY TO D2
    LSR.L   #3,D2                           * [D2] Temporarily used D2 for shifting bits            *TODO: DYNAMIC FOR ANY LOCATION OF SOURCE
    MOVE.L  D2,VAR_LONG_ADDRESS_MODE_CHECK  * BITS SHIFTED
    MOVE.L  #7,D2                           * SETTING UP MASKING FOR BITS (0-2)
    AND.L   D2,VAR_LONG_ADDRESS_MODE_CHECK  * MASKED VARIABLE HOLDING ADDRESS MODE TO COMPARE
                                            * [COMPARE] MODE WITH POSSIBLE ADDRESS MODES
    
    *MUST SET DESTINATION_REGISTER_FORMAT BEFORE CALLING GET_EA_EA_SRC
    *DESTINATION REGISTER FORMAT STANDARD         *
    *WHEN BIT = 1(INVALID ADDRESS MODE)           *
    *WHEN BIT = 0(VALID ADDRESS MODE)             *
    *BIT LOCATIONS 0-7 INDICATE ADDRESS MODES     *
    *0 - Dn                                       *
    *1 - An                                       *
    *2 - (An)                                     *
    *3 - (An)+                                    *
    *4 - -(An)                                    *
    *5 - (XXX).W                                  *
    *6 - (XXX).L                                  *
    *7 - #<data>                                  *
    ***********************************************
    
    *** Check if source ...  <ea> = Dn
CHECK0    
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  SRC_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          AND.B   #$01,TEMP_REGISTER_FORMAT                           * MASKS 0000 0001 
          CMPI.B   #$01,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 00000001) THAN INVALID ADDRESSMODE 
          BEQ     CHECK1                                              * SINCE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON
          CMPI.L     #0,VAR_LONG_ADDRESS_MODE_CHECK                      * (Dn) - COMPARE MODES TO SEE IF IT IS THIS MODE
          BNE     CHECK1
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'D',D3
          BSR       PUSH_STACK

          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_SRC_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
LOOP_SHIFTING
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     MASKING_NEXT              *IF SHIFTING FINISHED MOVE ON TO MASKING 
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUB.B   #1,D2                     *DECREMENT COUNTER
          BRA     LOOP_SHIFTING             *CONTINUE SHIFTING
MASKING_NEXT
          AND.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADD.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          BRA     GET_SRC_SUCCESS           *RETURN          
          
          
          *** Check if source ...  <ea> = An
CHECK1    LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  SRC_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          AND.B   #$02,TEMP_REGISTER_FORMAT                           * MASKS 0000 0010 
          CMP.B   #$02,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 00000010) THAN INVALID ADDRESSMODE 
          BEQ     CHECK2                                              * THE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON
          CMPI.L  #1,VAR_LONG_ADDRESS_MODE_CHECK                      * An - COMPARE MODES TO SEE IF IT IS THIS MODE
          BNE     CHECK2
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'A',D3
          BSR       PUSH_STACK

          
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_SRC_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2           *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
LOOP_SHIFTING1
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     MASKING_NEXT1              *IF SHIFTING FINISHED MOVE ON TO MASKING 
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUB.B   #1,D2                     *DECREMENT COUNTER
          BRA     LOOP_SHIFTING1             *CONTINUE SHIFTING
MASKING_NEXT1
          AND.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADD.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          BRA     GET_SRC_SUCCESS                   *RETURN 
          
          
          
          
          *** Check if source ...  <ea> = (An)       
CHECK2    LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  SRC_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B   #$04,TEMP_REGISTER_FORMAT                           * MASKS 0000 0100                                                       *change <SRC>*
          CMPI.B   #$04,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 00000100) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     CHECK3                                              * THE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON               *change: checkx++*
          CMPI.L   #2,VAR_LONG_ADDRESS_MODE_CHECK                      * (An)  COMPARE MODES TO SEE IF IT IS THIS MODE                                                                *change: checkx++*
          BNE     CHECK3
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"                                            *change CHARS TO PUSH*
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'(',D3
          BSR       PUSH_STACK
          MOVE.B    #'A',D3
          BSR       PUSH_STACK

          
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_SRC_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
LOOP_SHIFTING2                                                                                              *change: NAME OF LABEL*
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     MASKING_NEXT2             *IF SHIFTING FINISHED MOVE ON TO MASKING                        *change: NAME OF LABEL*
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUB.B   #1,D2                     *DECREMENT COUNTER
          BRA     LOOP_SHIFTING2            *CONTINUE SHIFTING                                              *change: NAME OF LABEL*
MASKING_NEXT2                                                                                               *change: NAME OF LABEL*
          ANDI.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADDI.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          MOVE.B    #')',D3                 *FINISH PUSHING LAST ')' INTO STACK
          BSR       PUSH_STACK
          
          BRA     GET_SRC_SUCCESS                   *RETURN 

          
          
                    
*** Check if source ...  <ea> = (An)+       
CHECK3    LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  SRC_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$08,TEMP_REGISTER_FORMAT                           * MASKS 0000 1000                                                     *change <SRC>*
          CMPI.B  #$08,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 00000010) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     CHECK4                                              * THE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON               *change: checkx++*
          CMPI.L  #3,VAR_LONG_ADDRESS_MODE_CHECK                      * (An)+ - COMPARE MODES TO SEE IF IT IS THIS MODE                                                                  *change: checkx++*
          BNE     CHECK4
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"                                            *change CHARS TO PUSH*
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'(',D3
          BSR       PUSH_STACK
          MOVE.B    #'A',D3
          BSR       PUSH_STACK

          
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_SRC_START_END, VAR_BYTE_END * GET ENDING INDEX
          ANDI.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
          
LOOP_SHIFTING3                                                                                              *change: NAME OF LABEL*
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     MASKING_NEXT3             *IF SHIFTING FINISHED MOVE ON TO MASKING                        *change: NAME OF LABEL*
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUBI.B   #1,D2                     *DECREMENT COUNTER
          BRA     LOOP_SHIFTING3            *CONTINUE SHIFTING 
                                             *change: NAME OF LABEL*
MASKING_NEXT3                                                                                               *change: NAME OF LABEL*
          ANDI.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADDI.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          MOVE.B    #')',D3                 *FINISH PUSHING LAST ')' INTO STACK
          BSR       PUSH_STACK
          MOVE.B    #'+',D3                 *FINISH PUSHING LAST ')' INTO STACK
          BSR       PUSH_STACK
          
          BRA       GET_SRC_SUCCESS                   *RETURN 

          
          
                    
          *** Check if source ...  <ea> = -(An)       
CHECK4    LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  SRC_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$10,TEMP_REGISTER_FORMAT                           * MASKS 0001 0000                                                     *change <SRC>*
          CMPI.B  #$10,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 0001 0000) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     CHECK7                                              * THE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON               *change: checkx++*
          CMPI.L  #4,VAR_LONG_ADDRESS_MODE_CHECK                      * -(An) - COMPARE MODES TO SEE IF IT IS THIS MODE                                                                  *change: checkx++*
          BNE     CHECK7
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"                                            *change CHARS TO PUSH*
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'-',D3
          BSR       PUSH_STACK
          MOVE.B    #'(',D3
          BSR       PUSH_STACK
          MOVE.B    #'A',D3
          BSR       PUSH_STACK

          
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_SRC_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
          
LOOP_SHIFTING4                                                                                              *change: NAME OF LABEL*
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     MASKING_NEXT4             *IF SHIFTING FINISHED MOVE ON TO MASKING                        *change: NAME OF LABEL*
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUBI.B   #1,D2                     *DECREMENT COUNTER
          BRA     LOOP_SHIFTING4            *CONTINUE SHIFTING 
                                             *change: NAME OF LABEL*
MASKING_NEXT4                                                                                               *change: NAME OF LABEL*
          ANDI.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADDI.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          MOVE.B    #')',D3                 *FINISH PUSHING LAST ')' INTO STACK
          BSR       PUSH_STACK
          
          BRA     GET_SRC_SUCCESS                   *RETURN
          
                    
          *** Check if source ...  <ea> = (XXX).W or (XXX).L or #<data>
CHECK7    CMPI.L  #7,VAR_LONG_ADDRESS_MODE_CHECK                      *IF (MODE != 111)
          BNE     GET_SRC_FAILED                                      *THAN BRANCH TO UNCESSFULL SRC MODE READ
                 
          *NEXT: (MODE == 111) 
          *NOW: CHECK FOR SRC REGISTER 
                *(000 = (xxx).W)
                *(001 = (xxx).L)
                *(010 = #<data>)
                
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_SRC_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D6
SRC_LOOP_SHIFTING
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     SRC_MASKING_NEXT              *IF SHIFTING FINISHED MOVE ON TO MASKING 
          LSR     #1,D6                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUB.B   #1,D2                     *DECREMENT COUNTER
          BRA     SRC_LOOP_SHIFTING             *CONTINUE SHIFTING
SRC_MASKING_NEXT
          AND.L   #7,D6                     *MASK, ONLY NEED 0-2 BIT INDEXES 
         *D3 - REGISTER NUMBER NEEDED TO CHECK WHICH W/L/#<DATA>*
         
CHECK_WORD  
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  SRC_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$20,TEMP_REGISTER_FORMAT                           * MASKS 0010 0000                                                     *change <SRC>*
          CMPI.B  #$20,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 0010 0000) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     CHECK_LONG                                      * THE REGISTER FORMAT DOES NOT ALLOW "(XXX).W" -> SO MOVE ON               *change: checkx++*
          CMPI.B  #0,D6                          
          BNE     CHECK_LONG 
          
          *IT IS A WORD AT THIS POINT*
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'$',D3
          BSR       PUSH_STACK
          MOVE.W    (A5)+,D1
          MOVE.L    #4,D2           *SIZE INITIALIZED FOR CONVERSION
          BSR       HEX2ASCII2STACK
          BRA     GET_SRC_SUCCESS

CHECK_LONG
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  SRC_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$40,TEMP_REGISTER_FORMAT                           * MASKS 0100 0000                                                     *change <SRC>*
          CMPI.B  #$40,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 0100 0000) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     CHECK_IMMEDIATE                                      * THE REGISTER FORMAT DOES NOT ALLOW "(XXX).W" -> SO MOVE ON               *change: checkx++*
          CMPI.B  #1,D6                          
          BNE     CHECK_IMMEDIATE  

          *IT IS A WORD AT THIS POINT*
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'$',D3
          BSR       PUSH_STACK
          MOVE.W    (A5)+,D1
          MOVE.L    #4,D2           *SIZE INITIALIZED FOR CONVERSION
          BSR       HEX2ASCII2STACK
          MOVE.W    (A5)+,D1
          MOVE.L    #4,D2           *SIZE INITIALIZED FOR CONVERSION
          BSR       HEX2ASCII2STACK
          BRA     GET_SRC_SUCCESS
          
CHECK_IMMEDIATE
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  SRC_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$80,TEMP_REGISTER_FORMAT                           * MASKS 0100 0000                                                     *change <SRC>*
          CMPI.B  #$80,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 0100 0000) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     GET_SRC_FAILED                                      * THE REGISTER FORMAT DOES NOT ALLOW "(XXX).W" -> SO MOVE ON               *change: checkx++*
          CMPI.B  #4,D6                          
          BNE     GET_SRC_FAILED 

          *IT IS A WORD AT THIS POINT*
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'#',D3
          BSR       PUSH_STACK
          MOVE.W    (A5)+,D1
          MOVE.L    #4,D2           *SIZE INITIALIZED FOR CONVERSION
          BSR       HEX2ASCII2STACK
          BRA     GET_SRC_SUCCESS
          
GET_SRC_FAILED    *SEND ERROR FLAG THAN CLEAN ALL REGISTERS/VARIABLES THAN PRINT OP_DATA
          MOVE.L #1,D4
          RTS
GET_SRC_SUCCESS 
          RTS
                               
    






GET_EA_EA_DEST
*PRECONDITION: 16 BIT DECODE DATA MUST BE IN REGISTER [D5]*
    
    *DETERMINE ADDRESS MODE OF EA WITH THE MODE CODE 
    MOVE.L  D5,D2                           * CLEAN COPY TO D2
    LSR.L   #6,D2                           * [D2] Temporarily used D2 for shifting bits                *TODO: DYNAMIC MODE LOCATION
    MOVE.L  D2,VAR_LONG_ADDRESS_MODE_CHECK  * BITS SHIFTED
    MOVE.L  #7,D2                           * SETTING UP MASKING FOR BITS (0-2)
    AND.L   D2,VAR_LONG_ADDRESS_MODE_CHECK  * MASKED VARIABLE HOLDING ADDRESS MODE TO COMPARE
                                            * [COMPARE] MODE WITH POSSIBLE ADDRESS MODES
    
    *MUST SET DESTINATION_REGISTER_FORMAT BEFORE CALLING GET_EA_EA_SRC
    *DESTINATION REGISTER FORMAT STANDARD         *
    *WHEN BIT = 1(INVALID ADDRESS MODE)           *
    *WHEN BIT = 0(VALID ADDRESS MODE)             *
    *BIT LOCATIONS 0-7 INDICATE ADDRESS MODES     *
    *0 - Dn                                       *
    *1 - An                                       *
    *2 - (An)                                     *
    *3 - (An)+                                    *
    *4 - -(An)                                    *
    *5 - (XXX).W                                  *
    *6 - (XXX).L                                  *
    *7 - #<data>                                  *
    ***********************************************
    
    *** Check if source ...  <ea> = Dn
DEST_CHECK0    
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  DEST_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          AND.B   #$01,TEMP_REGISTER_FORMAT                           * MASKS 0000 0001 
          CMPI.B   #$01,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 00000001) THAN INVALID ADDRESSMODE 
          BEQ     DEST_CHECK1                                              * SINCE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON
          CMPI.L     #0,VAR_LONG_ADDRESS_MODE_CHECK                      * (Dn) - COMPARE MODES TO SEE IF IT IS THIS MODE
          BNE     DEST_CHECK1
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'D',D3
          BSR       PUSH_STACK

          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_DST_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
DEST_LOOP_SHIFTING
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     DEST_MASKING_NEXT              *IF SHIFTING FINISHED MOVE ON TO MASKING 
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUB.B   #1,D2                     *DECREMENT COUNTER
          BRA     DEST_LOOP_SHIFTING             *CONTINUE SHIFTING
DEST_MASKING_NEXT
          AND.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADD.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          BRA     GET_DST_SUCCESS           *RETURN          
          
          
          *** Check if source ...  <ea> = An
DEST_CHECK1    
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  DEST_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          AND.B   #$02,TEMP_REGISTER_FORMAT                           * MASKS 0000 0010 
          CMP.B   #$02,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 00000010) THAN INVALID ADDRESSMODE 
          BEQ     DEST_CHECK2                                              * THE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON
          CMPI.L  #1,VAR_LONG_ADDRESS_MODE_CHECK                      * An - COMPARE MODES TO SEE IF IT IS THIS MODE
          BNE     DEST_CHECK2
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'A',D3
          BSR       PUSH_STACK

          
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_DST_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2           *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
DEST_LOOP_SHIFTING1
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     DEST_MASKING_NEXT1              *IF SHIFTING FINISHED MOVE ON TO MASKING 
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUB.B   #1,D2                     *DECREMENT COUNTER
          BRA     DEST_LOOP_SHIFTING1             *CONTINUE SHIFTING
DEST_MASKING_NEXT1
          AND.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADD.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          BRA     GET_DST_SUCCESS                   *RETURN 
          
          
          
          
          *** Check if source ...  <ea> = (An)       
DEST_CHECK2    
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  DEST_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B   #$04,TEMP_REGISTER_FORMAT                           * MASKS 0000 0100                                                       *change <SRC>*
          CMPI.B   #$04,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 00000100) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     DEST_CHECK3                                              * THE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON               *change: checkx++*
          CMPI.L   #2,VAR_LONG_ADDRESS_MODE_CHECK                      * (An)  COMPARE MODES TO SEE IF IT IS THIS MODE                                                                *change: checkx++*
          BNE     DEST_CHECK3
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"                                            *change CHARS TO PUSH*
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'(',D3
          BSR       PUSH_STACK
          MOVE.B    #'A',D3
          BSR       PUSH_STACK

          
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_DST_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
DEST_LOOP_SHIFTING2                                                                                              *change: NAME OF LABEL*
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     DEST_MASKING_NEXT2             *IF SHIFTING FINISHED MOVE ON TO MASKING                        *change: NAME OF LABEL*
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUB.B   #1,D2                     *DECREMENT COUNTER
          BRA     DEST_LOOP_SHIFTING2            *CONTINUE SHIFTING                                              *change: NAME OF LABEL*
DEST_MASKING_NEXT2                                                                                               *change: NAME OF LABEL*
          ANDI.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADDI.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          MOVE.B    #')',D3                 *FINISH PUSHING LAST ')' INTO STACK
          BSR       PUSH_STACK
          
          BRA     GET_DST_SUCCESS                   *RETURN 

          
          
                    
*** Check if source ...  <ea> = (An)+       
DEST_CHECK3    LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  DEST_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$08,TEMP_REGISTER_FORMAT                           * MASKS 0000 1000                                                     *change <SRC>*
          CMPI.B  #$08,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 00000010) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     DEST_CHECK4                                              * THE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON               *change: checkx++*
          CMPI.L  #3,VAR_LONG_ADDRESS_MODE_CHECK                      * (An)+ - COMPARE MODES TO SEE IF IT IS THIS MODE                                                                  *change: checkx++*
          BNE     DEST_CHECK4
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"                                            *change CHARS TO PUSH*
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'(',D3
          BSR       PUSH_STACK
          MOVE.B    #'A',D3
          BSR       PUSH_STACK

          
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_DST_START_END, VAR_BYTE_END * GET ENDING INDEX
          ANDI.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
          
DEST_LOOP_SHIFTING3                                                                                              *change: NAME OF LABEL*
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     DEST_MASKING_NEXT3             *IF SHIFTING FINISHED MOVE ON TO MASKING                        *change: NAME OF LABEL*
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUBI.B   #1,D2                     *DECREMENT COUNTER
          BRA     DEST_LOOP_SHIFTING3            *CONTINUE SHIFTING 
                                             *change: NAME OF LABEL*
DEST_MASKING_NEXT3                                                                                               *change: NAME OF LABEL*
          ANDI.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADDI.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          MOVE.B    #')',D3                 *FINISH PUSHING LAST ')' INTO STACK
          BSR       PUSH_STACK
          MOVE.B    #'+',D3                 *FINISH PUSHING LAST ')' INTO STACK
          BSR       PUSH_STACK
          
          BRA       GET_DST_SUCCESS                   *RETURN 

          
          
                    
          *** Check if source ...  <ea> = -(An)       
DEST_CHECK4    
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  DEST_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$10,TEMP_REGISTER_FORMAT                           * MASKS 0001 0000                                                     *change <SRC>*
          CMPI.B  #$10,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 0001 0000) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     DEST_CHECK7                                              * THE REGISTER FORMAT DOES NOT ALLOW "Dn" -> SO MOVE ON               *change: checkx++*
          CMPI.L  #4,VAR_LONG_ADDRESS_MODE_CHECK                      * -(An) - COMPARE MODES TO SEE IF IT IS THIS MODE                                                                  *change: checkx++*
          BNE     DEST_CHECK7
          
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"                                            *change CHARS TO PUSH*
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'-',D3
          BSR       PUSH_STACK
          MOVE.B    #'(',D3
          BSR       PUSH_STACK
          MOVE.B    #'A',D3
          BSR       PUSH_STACK

          
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_DST_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D3
          
DEST_LOOP_SHIFTING4                                                                                              *change: NAME OF LABEL*
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     DEST_MASKING_NEXT4             *IF SHIFTING FINISHED MOVE ON TO MASKING                        *change: NAME OF LABEL*
          LSR     #1,D3                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUBI.B   #1,D2                     *DECREMENT COUNTER
          BRA     DEST_LOOP_SHIFTING4            *CONTINUE SHIFTING 
                                             *change: NAME OF LABEL*
DEST_MASKING_NEXT4                                                                                               *change: NAME OF LABEL*
          ANDI.L   #7,D3                     *MASK, ONLY NEED 0-2 BIT INDEXES
          ADDI.B   #$30,D3                   *CONVERT TO CHAR
          BSR     PUSH_STACK                *PUSH TO STACK
          
          MOVE.B    #')',D3                 *FINISH PUSHING LAST ')' INTO STACK
          BSR       PUSH_STACK
          
          BRA     GET_DST_SUCCESS                   *RETURN
          
                    
          *** Check if source ...  <ea> = (XXX).W or (XXX).L or #<data>
DEST_CHECK7    
          CMPI.L  #7,VAR_LONG_ADDRESS_MODE_CHECK                      *IF (MODE != 111)
          BNE     GET_DST_FAILED                                      *THAN BRANCH TO UNCESSFULL SRC MODE READ
                 
          *NEXT: (MODE == 111) 
          *NOW: CHECK FOR SRC REGISTER 
                *(000 = (xxx).W)
                *(001 = (xxx).L)
                *(010 = #<data>)
                
          *FIND REGISTER NUMBER END LOCATION*  
          MOVE.B  GET_DST_START_END, VAR_BYTE_END * GET ENDING INDEX
          AND.B   #$0F,VAR_BYTE_END
          
          *GET INDEX OF THE END OF SRC REGISTER NUMBER
          MOVE.L  D5,VAR_TEMP_CLEANCOPY     *COPY DATA
          MOVE.B  VAR_BYTE_END,D2          *PUT END LOCATION INTO D2
          
          *INTITIALIZE FOR BIT SHIFTING
          LEA     VAR_TEMP_CLEANCOPY,A0
          MOVE.L  VAR_TEMP_CLEANCOPY,D6
DEST_LOOP_SHIFTING7
          CMPI.B   #0,D2                     *D2 - ACTS AS COUNTER TO HOW MANY SHIFTS TAKE PLACE
          BEQ     DEST_MASKING_NEXT7              *IF SHIFTING FINISHED MOVE ON TO MASKING 
          LSR     #1,D6                     *SHIFT VAR_TEMP_CLEANCOPY UNTIL REGISTER IS COMPLETED
          SUB.B   #1,D2                     *DECREMENT COUNTER
          BRA     DEST_LOOP_SHIFTING7             *CONTINUE SHIFTING
DEST_MASKING_NEXT7
          AND.L   #7,D6                     *MASK, ONLY NEED 0-2 BIT INDEXES 
         *D3 - REGISTER NUMBER NEEDED TO CHECK WHICH W/L/#<DATA>*
          
DEST_CHECK_WORD  
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  DEST_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$20,TEMP_REGISTER_FORMAT                           * MASKS 0010 0000                                                     *change <SRC>*
          CMPI.B  #$20,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 0010 0000) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     DEST_CHECK_LONG                                      * THE REGISTER FORMAT DOES NOT ALLOW "(XXX).W" -> SO MOVE ON               *change: checkx++*
          CMPI.B  #0,D6                                                   *COMPARE REGISTER NUMBER WITH (000 == 000) FOR WORD
          BNE     DEST_CHECK_LONG                                      * THE REGISTER NUMBER DOESN'T MATCH "(XXX).W" -> SO MOVE ON       
          *IT IS A WORD AT THIS POINT*
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'$',D3
          BSR       PUSH_STACK
          MOVE.W    (A5)+,D1
          MOVE.L    #4,D2           *SIZE INITIALIZED FOR CONVERSION
          BSR       HEX2ASCII2STACK
          BRA       GET_DST_SUCCESS

DEST_CHECK_LONG
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  DEST_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$40,TEMP_REGISTER_FORMAT                           * MASKS 0100 0000                                                     *change <SRC>*
          CMPI.B  #$40,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 0100 0000) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     DEST_CHECK_IMMEDIATE                                      * THE REGISTER FORMAT DOES NOT ALLOW "(XXX).W" -> SO MOVE ON               *change: checkx++*
          CMPI.B  #1,D6                                                   *COMPARE REGISTER NUMBER WITH (001 == 001) FOR WORD
          BNE     DEST_CHECK_IMMEDIATE                                      * THE REGISTER NUMBER DOESN'T MATCH "(XXX).L" -> SO MOVE ON 
          *IT IS A WORD AT THIS POINT*
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'$',D3
          BSR       PUSH_STACK
          MOVE.W    (A5)+,D1        * GET NEXT WORD INTO STACK
          MOVE.L    #4,D2           * SETS SIZE = 4 FOR CONVERSION TO ASCII
          BSR       HEX2ASCII2STACK
          MOVE.W    (A5)+,D1        * GET NEXT WORD INTO STACK
          MOVE.L    #4,D2          
          BSR       HEX2ASCII2STACK
          BRA     GET_DST_SUCCESS
          
DEST_CHECK_IMMEDIATE
          LEA     TEMP_REGISTER_FORMAT,A0
          MOVE.B  DEST_REGISTER_FORMAT, D2                             *COPY FORMAT TO TEMP VARIABLE
          MOVE.B  D2, (A0)                                            *COPY FORMAT TO TEMP VARIABLE
          ANDI.B  #$80,TEMP_REGISTER_FORMAT                           * MASKS 0100 0000                                                     *change <SRC>*
          CMPI.B  #$80,TEMP_REGISTER_FORMAT                           * IF(TEMP_REGISTER_FORMAT == 0100 0000) THAN INVALID ADDRESSMODE       *change <SRC>*
          BEQ     GET_DST_FAILED                                      * THE REGISTER FORMAT DOES NOT ALLOW "(XXX).W" -> SO MOVE ON               *change: checkx++*
          CMPI.B  #4,D6                                               * COMPARE REGISTER NUMBER WITH (010 == 010) FOR WORD
          BNE     GET_DST_FAILED                                      * THE REGISTER NUMBER DOESN'T MATCH "#<DATA>" -> SO MOVE ON 
          
          *IT IS A WORD AT THIS POINT*
          *PUSH "Dn" INTO STACK, BUT FIND MAKE SURE TO FIND "n"
          MOVE.B    #' ',D3
          BSR       PUSH_STACK
          MOVE.B    #'#',D3
          BSR       PUSH_STACK
          MOVE.W    (A5)+,D1
          MOVE.L    #4,D2           *SIZE INITIALIZED FOR CONVERSION
          BSR       HEX2ASCII2STACK
          BRA       GET_DST_SUCCESS
          
GET_DST_FAILED    *SEND ERROR FLAG THAN CLEAN ALL REGISTERS/VARIABLES THAN PRINT OP_DATA
          MOVE.L #1,D4
          RTS
GET_DST_SUCCESS 
          RTS


*---------------------------------------------------------------------------*
* STACK/QUEUE INTERFACE
*---------------------------------------------------------------------------*
PRINT_STACK
          CMP.B     #0,COUNTER
          BEQ       PRINT_STACK_RETURN             *CHECK IF LOOP IS FINISHED
          
PRINT_STACK_HELPER
          BSR      POP_STACK          *PRINTS ADDRESS
          MOVE.B   #6,D0              *Display single character in D1.B. 
          TRAP     #15             *ACTIVATES PRINT

          BRA       PRINT_STACK
PRINT_STACK_RETURN
          RTS
          
          
PRINT_QUEUE
          CMP.B     #0,COUNTER
          BEQ       PRINT_QUEUE_RETURN             *CHECK IF LOOP IS FINISHED
          
PRINT_QUEUE_HELPER
          MOVE.W   COUNTER,QUEUE_COUNTER
          BSR      POP_FRONT          *PRINTS ADDRESS
          MOVE.B   #6,D0              *Display single character in D1.B. 
          TRAP     #15             *ACTIVATES PRINT

          BRA       PRINT_QUEUE
PRINT_QUEUE_RETURN
          RTS
          
*PUSHES.W CONTENTS OF [D3] INTO STACK          
PUSH_STACK
            MOVE.B  D3,-(A2)
            BSR     INCREMENT
            RTS
*POPS.W TOP OF STACK INTO [D1], SO ITS READY TO PRINT WITH TRAP 15
*         MOVE.W   (A2)+,D1           *PRINTS ADDRESS
*         MOVE.B   #15,D0             *PRINTS ACCORDING TO D2 BASE VALUE
*         MOVE.B   #16,D2             *PRINTS BASED 16 NUMBER
*         TRAP        #15             *ACTIVATES PRINT
POP_STACK
            CMPA.W   A2,SP            *CHECKS IF THERE IS ANYTHING TO PUSH
            BEQ     POP_RETURN        *IF NOTHING TO PUSH THAN JUST RETURN
            MOVE.B  (A2)+,D1 
            BSR     DECREMENT
POP_RETURN
            RTS 
      
*USE [A4] AS SECOND POINTER IN SHIFTING      
POP_FRONT   CMP.B   #0,QUEUE_COUNTER            *CHECKS IF
            BEQ     POP_FRONT_RETURN            *END LOOP ONCE COUNTER REACHES ZERO
            
            
            *POSITION THE POINTERS A[4] RIGHT BEHIND A[2] WHICH IS RIGHT BEHIND STACK
            MOVEA.W #STACK,A2   *START A2 AT STACK
            ADD.B   #0,-(A2)    *SHIFT A2 TO THE BOTTOM OF THE STACK
            MOVEA.W A2,A4     *START A4 RIGHT ABOVE A2
            ADD.B   #0,-(A4)  *leash one more higher in stack (a4)
            MOVE.B  (A2),D1     *POP CONTENTS INTO D1
POP_SHIFT_LOOP
            CMP.B   #0,QUEUE_COUNTER            *CHECKS IF
            BEQ     POP_FRONT_RETURN            *END LOOP ONCE COUNTER REACHES ZERO
            MOVE.B  (A4),(A2)   *SHIFT CONTENT DOWN THE STACK
            ADD.B   #0,-(A4)
            ADD.B   #0,-(A2) *SHIFT POINTERS DOWN THE STACK
            SUB.B   #1,QUEUE_COUNTER *DECREMENT INTERNAL QUEUE COUNTER
            
            BRA     POP_SHIFT_LOOP
                        
POP_FRONT_RETURN 
            *RESET A2 BACK TO SP
            MOVEA.W #STACK,A2    
            SUB.B   #1,COUNTER *DECREMENT STACK COUNTER       
            RTS   

INCREMENT
            ADD.B   #1, COUNTER
            RTS           
DECREMENT
            SUB.B   #1, COUNTER
            RTS           
CLEAR_STACK
            CMP.B     #0,COUNTER
            BEQ       CLEAR_RETURN
            BSR       POP_STACK
            BRA       CLEAR_STACK
 
CLEAR_RETURN
            RTS    
            
*---------------------------------------------------------------------------*
* 8/16/32-bit Address getter
*---------------------------------------------------------------------------*
*get displacement value from bits 0 to 8
*if displacement is not $00, than it is 8 otherwise check for word
*if displacement is not $FF, than it is a long
*add the displacement to the current address being processed + a word
*place results into D3, so that it can be pushed to stack
GET_DISPLACEMENT_ADDRESS
            MOVE.L  D5,D4                   * COPIES DATA INTO D6
            ANDI.L  #$00FF,D6               * MASKS DATA
            CMPI.L  #$00,D4                 * COMPARES DATA IF IT IS WORD
            BEQ     GET_DISPLACEMENT_WORD
            CMPI.L  #$FF,D4                 * COMPARES DATA IF IT IS LONG
            BEQ     GET_DISPLACEMENT_LONG
            
            MOVE.L  #$100,D7                 *FILL D7 WITH FF SO THAT IT CAN BE SUBTRACTED BY THE DISPLACEMENT GIVING US THE REAL DISPLACEMENT
            SUB.B   D4,D7
            
            MOVE.L  A5,D4                   * PC+2 ADDRESS INTO D6
            SUB.B   D7,D4                   * SUBTRACT "DISPLACEMENT + 2 " TO GET THE ORIGINAL ADDRESS BEING BRANCH TO
            MOVE.L  #4,D2
            MOVE.L  D4,D1  
            BSR     HEX2ASCII2STACK
            RTS
            
GET_DISPLACEMENT_WORD
            MOVE.L  #$FF,D7                 *FILL D7 WITH FF SO THAT IT CAN BE SUBTRACTED BY THE DISPLACEMENT GIVING US THE REAL DISPLACEMENT
            SUB.B   D4,D7
            
            MOVE.L  A5,D4                   * PC+2 ADDRESS INTO D6
            SUB.B   D7,D4                   * SUBTRACT "DISPLACEMENT + 2 " TO GET THE ORIGINAL ADDRESS BEING BRANCH TO
            MOVE.L  #4,D2
            MOVE.L  D4,D3
            MOVE.L  D4,D1
            BSR     HEX2ASCII2STACK
            RTS     
GET_DISPLACEMENT_LONG   
            MOVE.L  #$FF,D7                 *FILL D7 WITH FF SO THAT IT CAN BE SUBTRACTED BY THE DISPLACEMENT GIVING US THE REAL DISPLACEMENT
            SUB.B   D4,D7
            
            MOVE.L  A5,D4                   * PC+2 ADDRESS INTO D6
            SUB.B   D7,D4                   * SUBTRACT "DISPLACEMENT + 2 " TO GET THE ORIGINAL ADDRESS BEING BRANCH TO
            MOVE.L  #8,D2
            MOVE.L  D4,D3                   * PREPARE TO PUSH
            MOVE.L  D4,D1
            BSR     HEX2ASCII2STACK

            CLR.L   D4
            RTS

*---------------------------------------------------------------------------*
* TERMINATE
*---------------------------------------------------------------------------*
TERMINATE   
            LEA     FINMSG,A1
            MOVE.B  #14,D0
            TRAP    #15

            MOVE.B  #9,D0
            TRAP    #15

*---------------------------------------------------------------------------*
* Data storage                                                 
*---------------------------------------------------------------------------*  
WELCOME
            DC.B '                         ___     ___ ___        ___   ___ ___                 ',CR,LF
            DC.B '=====           \  /\  /|___|   |   |   ||\  /||___    | |   |           =====',CR,LF
            DC.B '=====            \/  \/ |___|___|___|___|| \/ ||___    | |___|           =====',CR,LF
    
            DC.B '                        ___ ___ ___  ___      ___                             ',CR,LF
            DC.B '                       |     | |___)|    |   |___                             ',CR,LF 
            DC.B '                       |___ _|_|\___|___ |___|___                             ',CR,LF
    
            DC.B '           __  ___ ___   _   ___  ___  ___        ___      ___ ___            ',CR,LF
            DC.B '=====     |  \  | |___  /_\ |___ |___ |___ |\  /||___||   |___|___)      =====',CR,LF 
            DC.B '=====     |__/ _|_ ___|/   \ ___| ___||___ | \/ ||___||___|___|\___      =====',CR,LF,CR,LF,CR,LF,0

PROMPT_START
            DC.B    'Please enter a hexadecimal starting address.',CR,LF,0
    
PROMPT_END
            DC.B    'Please enter a hexadecimal ending address.',CR,LF,0
DISP_NEXT   DC.B    CR,LF,'Hit Enter to print the next 30 lines.',CR,LF,0            
REPEATMSG   DC.B    'Would you like to run again? Press Y to continue or N to finish.',CR,LF,0
FINMSG      DC.B    'Thank you for using Circle Disassembler.',CR,LF,0
ERRMSG_1    DC.B    'Error: Invalid Input Address',CR,LF,0
ERRMSG_3    DC.B    'Error: Invalid Input Address (Odd)',CR,LF,0
ERRMSG_5    DC.B    'Error: Invalid Input Address (start > end)',CR,LF,0

VR_S_ADDR   DS.B    80                      * allocate storage space for the starting address
VR_E_ADDR   DS.B    80                      * allocate storage space for the ending address
S_ADDR_HX   DS.L    1                       * allocate storage space for the starting address in hex
E_ADDR_HX   DS.L    1                       * allocate storage space for the ending address in hex
ENDLINE_M   DC.B    CR,LF,0
TMPINPUT    DS.B    80                      * temp store user input
TMPOUTPUT   DS.B    80                      * temp store prog output
DISP_ORI_B  DC.B    '   ORI.B',0
DISP_ORI_W  DC.B    '   ORI.W',0
DISP_ORI_L  DC.B    '   ORI.L',0
DISP_EORI_B  DC.B    '   EORI.B',0
DISP_EORI_W  DC.B    '   EORI.W',0
DISP_EORI_L  DC.B    '   EORI.L',0
DISP_BTST   DC.B    '   BTST',0
DISP_CMPI_B  DC.B    '   CMPI.B',0
DISP_CMPI_W  DC.B    '   CMPI.W',0
DISP_CMPI_L  DC.B    '   CMPI.L',0
DISP_DATA   DC.B    '   DATA',0
DISP_MOVE_B DC.B    '   MOVE.B',0
DISP_MOVE_W DC.B    '   MOVE.W',0
DISP_MOVE_L DC.B    '   MOVE.L',0
DISP_RTS    DC.B    '   RTS',0
DISP_JSR    DC.B    '   JSR',0
DISP_NEG_B    DC.B    '   NEG.B',0
DISP_NEG_W    DC.B    '   NEG.W',0
DISP_NEG_L    DC.B    '   NEG.L',0
DISP_NOT_B  DC.B    '   NOT.B',0
DISP_NOT_W  DC.B    '   NOT.W',0
DISP_NOT_L  DC.B    '   NOT.L',0
DISP_LEA    DC.B    '   LEA',0
DISP_MOVEM_W    DC.B    '   MOVEM.W',0
DISP_MOVEM_L    DC.B    '   MOVEM.L',0
DISP_ADDQ_B DC.B    '   ADDQ.B',0
DISP_ADDQ_W DC.B    '   ADDQ.W',0
DISP_ADDQ_L DC.B    '   ADDQ.L',0
DISP_DIVS   DC.B    '   DIVS',0
DISP_SUB_B  DC.B    '   SUB.B',0
DISP_SUB_W  DC.B    '   SUB.W',0
DISP_SUB_L  DC.B    '   SUB.L',0
DISP_SUBI_B  DC.B    '   SUBI.B',0
DISP_SUBI_W  DC.B    '   SUBI.W',0
DISP_SUBI_L  DC.B    '   SUBI.L',0
DISP_SUBA_W  DC.B    '   SUBA.W',0
DISP_SUBA_L  DC.B    '   SUBA.L',0
DISP_EOR_B  DC.B    '   EOR.B',0
DISP_EOR_W  DC.B    '   EOR.W',0
DISP_EOR_L  DC.B    '   EOR.L',0
DISP_CMP_B  DC.B    '   CMP.B',0
DISP_CMP_W  DC.B    '   CMP.W',0
DISP_CMP_L  DC.B    '   CMP.L',0
DISP_CMPA_W  DC.B    '   CMPA.W',0
DISP_CMPA_L  DC.B    '   CMPA.L',0
DISP_MULS_W DC.B    '   MULS.W',0
DISP_AND_B  DC.B    '   AND.B',0
DISP_AND_W  DC.B    '   AND.W',0
DISP_AND_L  DC.B    '   AND.L',0
DISP_ADD_B  DC.B    '   ADD.B',0
DISP_ADD_W  DC.B    '   ADD.W',0
DISP_ADD_L  DC.B    '   ADD.L',0
DISP_ADDA_W DC.B    '   ADDA.W',0
DISP_ADDA_L DC.B    '   ADDA.L',0
DISP_LSR_B  DC.B    '   LSR.B',0
DISP_LSL_B  DC.B    '   LSL.B',0
DISP_LSR_W  DC.B    '   LSR.W',0
DISP_LSL_W  DC.B    '   LSL.W',0
DISP_LSR_L  DC.B    '   LSR.L',0
DISP_LSL_L  DC.B    '   LSL.L',0
DISP_ASR_B  DC.B    '   ASR.B',0
DISP_ASL_B  DC.B    '   ASL.B',0
DISP_ASR_W  DC.B    '   ASR.W',0
DISP_ASL_W  DC.B    '   ASL.W',0
DISP_ASR_L  DC.B    '   ASR.L',0
DISP_ASL_L  DC.B    '   ASL.L',0
DISP_ROR_B  DC.B    '   ROR.B',0
DISP_ROL_B  DC.B    '   ROL.B',0
DISP_ROR_W  DC.B    '   ROR.W',0
DISP_ROL_W  DC.B    '   ROL.W',0
DISP_ROR_L  DC.B    '   ROR.L',0
DISP_ROL_L  DC.B    '   ROL.L',0
DISP_BRA    DC.B    '   BRA',0
DISP_BLT    DC.B    '   BLT',0
DISP_BEQ    DC.B    '   BEQ',0
DISP_BNE    DC.B    '   BNE',0
DISP_BHI    DC.B    '   BHI',0
DISP_MOVEA_W    DC.B    '   MOVEA.W',0
DISP_MOVEA_L    DC.B    '   MOVEA.L',0

DISP_HEX     DC.B    '   $',0
DISP_D  DC.B    '   D',0
DISP_A  DC.B    '   A',0
DISP_OP  DC.B    '   (',0
DISP_CP  DC.B   ')',0
DISP_AOP  DC.B    '   (A',0

DISP_PRE    DC.B    '   -(A',0
DISP_POST   DC.B    ')+',0
DISP_LB DC.B    '   #',0
DISP_0  DC.B    '0',0
DISP_1  DC.B    '1',0
DISP_2  DC.B    '2',0
DISP_3  DC.B    '3',0
DISP_4  DC.B    '4',0
DISP_5  DC.B    '5',0
DISP_6  DC.B    '6',0
DISP_7  DC.B    '7',0

*STACK INTERFACE VARIABLES*
COUNTER         DS.W    1
QUEUE_COUNTER   DS.W    1

*EA DECODING INTERFACE VARIABLES* 
DEST_REGISTER_FORMAT    DS.B    1           *all address modes acceptable standard
SRC_REGISTER_FORMAT  DS.B    1           *all address modes acceptable standard
TEMP_REGISTER_FORMAT    DS.B    1           *place holder for masking other register formats

*FORMAT OF WHERE TO GET THE EA BY THE ENDING BIT AND STARTING BIT
* WORD + WORD = LONG
* (STARTING BIT) + (ENDING BIT) = 2 HEX CHAR
* A              + F            = AF         <= EXAMPLE
*(10TH BIT)      + (15TH BIT)   = CHECK BITS 15 THROUGH 10
GET_DST_START_END    DS.B    1
GET_SRC_START_END    DS.B    1

*STORES THE START + END BITS HERE (FROM ABOVE)
VAR_BYTE_START      DS.L    1
VAR_BYTE_END        DS.L    1
VAR_TEMP_CLEANCOPY  DS.L    1

VAR_LONG_ADDRESS_MODE_CHECK        DS.L    1       *holds the bits 0-2 in long form

*MORE FOR STACK USAGE*
DISP_COMMA  DC.B    ',',0
DISP_INDENT  DC.B    '   ',0

*NEXT WORD POINTER: FOR IDENTIFING (xxx).W or (xxx).L*
POINTER_WORD    DS.W       1



*---------------------------------------------------------------------------*
* Ends program
*---------------------------------------------------------------------------*
            END    START                    * last line of source
















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
