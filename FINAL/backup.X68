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
* D4 - Opcode size (0 - byte; 1- word; 2-long)
* D5 - Processing data
* D6 - Loop counter to print 30 lines
* D7 - Error flag
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

*---------------------------------------------------------------------------*
* MAIN
* A5: Processing address
*---------------------------------------------------------------------------*  
MAIN        
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

            * process the first 4 most significant bits 
            *CLR.L   D1                      * clear for temp storage
            MOVE.L  D5,D1                    * copy the current processing data to D1
            MOVE.B  #12,D2                   * shift to right by 12 bits
            LSR.W   D2,D1             			
            MULU    #6,D1                    * form offset
            LEA     JMPTABLE,A1              * index into table
            JSR     0(A1,D1)                 * jump indirect with index
            
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
JMPTABLE    JMP     OP0000  * CMPI/ORI/BTST/EORI/SUBI/BTST
            JMP     OP0001  * MOVE.B
            JMP     OP0010  * MOVE.L/MOVEA.L
            JMP     OP0011  * MOVE.W/MOVEA.W
            JMP     OP0100  * MOVEM/LEA/NEG/NOT/JSR/RTS
            JMP     OP0101  * ADDQ
            JMP     OP0110  * BRA/Bcc (BEQ/BNE/BLT/BHI)
            JMP     OP0111  * MOVEQ (unassigned)
            JMP     OP1000  * DIVS
            JMP     OP1001  * SUB/SUBA
            JMP     OP1010  * Unassigned 
            JMP     OP1011  * CMP/EOR/CMPA
            JMP     OP1100  * MULS/AND
            JMP     OP1101  * ADD/ADDA
            JMP     OP1110  * LSR/LSL/ASR/ASL/ROL/ROR
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
            BEQ     OP_CMPI
            
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
            ROR.L   #5,D1
            ANDI.L  #$8,D1
            CMPI.B  #8,D1
            BEQ     OP_BTST

            * OP0000 series other than ORI/CMPI/BTST/EORI
            JMP     OP_DATA
            
*---------------------------------------------------------------------------*
* OP_BTST: display BTST
*---------------------------------------------------------------------------* 
OP_BTST     LEA     DISP_BTST,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS

*---------------------------------------------------------------------------*
* OP_EORI: decode and display EORI
*---------------------------------------------------------------------------* 
OP_EORI
            CLR.L   D1
            CLR.L   D4
            MOVE.L  D5,D1
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            CMPI.B  #0,D1
            BEQ     OP_EORI_B    * size is byte
            CMPI.B  #1,D1
            BEQ     OP_EORI_W    * size is word
            CMPI.B  #2,D1
            BEQ     OP_EORI_L    * size is long

OP_EORI_B    * size is byte    
            MOVE.B  #0,D4
            LEA     DISP_EORI_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_EORI_W    * size is word
            MOVE.B  #1,D4
            LEA     DISP_EORI_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_EORI_L    * size is long
            MOVE.B  #2,D4
            LEA     DISP_EORI_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
*---------------------------------------------------------------------------*
* OP_SUBI: decode SUBI.B/.W/.L
*---------------------------------------------------------------------------* 
OP_SUBI
            CLR.L   D1
            CLR.L   D4
            MOVE.L  D5,D1
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            CMPI.B  #0,D1
            BEQ     OP_SUBI_B    * size is byte
            CMPI.B  #1,D1
            BEQ     OP_SUBI_W    * size is word
            CMPI.B  #2,D1
            BEQ     OP_SUBI_L    * size is long

OP_SUBI_B    * size is byte    
            MOVE.B  #0,D4
            LEA     DISP_SUBI_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_SUBI_W    * size is word
            MOVE.B  #1,D4
            LEA     DISP_SUBI_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_SUBI_L    * size is long
            MOVE.B  #2,D4
            LEA     DISP_SUBI_L,A1
            MOVE.B  #14,D0
            TRAP    #15
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
OP_CMPI
            CLR.L   D1
            CLR.L   D4
            MOVE.L  D5,D1
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            CMPI.B  #0,D1
            BEQ     OP_CMPI_B    * size is byte
            CMPI.B  #1,D1
            BEQ     OP_CMPI_W    * size is word
            CMPI.B  #2,D1
            BEQ     OP_CMPI_L    * size is long

OP_CMPI_B    * size is byte    
            MOVE.B  #0,D4
            LEA     DISP_CMPI_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_CMPI_W    * size is word
            MOVE.B  #1,D4
            LEA     DISP_CMPI_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_CMPI_L    * size is long
            MOVE.B  #2,D4
            LEA     DISP_CMPI_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
 
*---------------------------------------------------------------------------*
* OP_ORI : decode ORI and its size
*---------------------------------------------------------------------------* 
OP_ORI      
            CLR.L   D1
            CLR.L   D4
            MOVE.L  D5,D1
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            CMPI.B  #0,D1
            BEQ     OP_ORI_B    * size is byte
            CMPI.B  #1,D1
            BEQ     OP_ORI_W    * size is word
            CMPI.B  #2,D1
            BEQ     OP_ORI_L    * size is long

OP_ORI_B    * size is byte    
            MOVE.B  #0,D4
            LEA     DISP_ORI_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_ORI_W    * size is word
            MOVE.B  #1,D4
            LEA     DISP_ORI_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_ORI_L    * size is long
            MOVE.B  #2,D4
            LEA     DISP_ORI_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
        
*---------------------------------------------------------------------------*
* OP0001: MOVE.B/MOVEA.B
*---------------------------------------------------------------------------*
OP0001      
            * clear registers to store temp data
            CLR.L   D0                      
            CLR.L   D1        
            CLR.L   D4                      
            MOVEA.L #0, A1                  
            MOVE.L  D5,D1
            ROR.L   #5,D1
            ANDI.L  #$E,D1
            CMPI.B  #2,D1
            BEQ     OP_MOVEA_B
            
            JMP     OP_MOVE_B   * display MOVE.B
            
*---------------------------------------------------------------------------*
* OP_MOVE_B: display MOVE_B and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVE_B 
            MOVE.B  #0,D4
            LEA     DISP_MOVE_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            JMP     EA_GEN

            RTS
            
*---------------------------------------------------------------------------*
* OP_MOVEA_B: display MOVEA_B and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVEA_B 
            MOVE.B  #0,D4
            LEA     DISP_MOVEA_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            JMP     EA_MOVEA

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
            MOVE.B  #2,D4
            MOVEA.L #0, A1
            LEA     DISP_MOVE_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            JSR     EA_GEN
            RTS

*---------------------------------------------------------------------------*
* OP_MOVEA_L: display MOVEA_L and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVEA_L 
            MOVE.B  #2,D4
            MOVEA.L #0, A1
            LEA     DISP_MOVEA_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            JMP     EA_MOVEA

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
            ROR.L   #5,D1
            ANDI.L  #$E,D1
            CMPI.B  #2,D1
            BEQ     OP_MOVEA_W
            
            JMP     OP_MOVE_W
          
*---------------------------------------------------------------------------*
* OP_MOVE_W: display MOVE_W and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVE_W   
            MOVE.B  #1,D4
            MOVEA.L #0, A1
            LEA     DISP_MOVE_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            JMP     EA_GEN

            RTS

*---------------------------------------------------------------------------*
* OP_MOVEA_W: display MOVEA and proceed to EA
*---------------------------------------------------------------------------*
OP_MOVEA_W 
            MOVE.B  #1,D4
            MOVEA.L #0, A1
            LEA     DISP_MOVEA_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            JMP     EA_MOVEA

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
            ROR.L   #8,D1
            CMPI.B  #1,D1
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
            LEA     DISP_LEA,A1
            MOVE.B  #14,D0
            TRAP    #15
            JMP     EA_MOVEA

            RTS

*---------------------------------------------------------------------------*
* OP_NEG: decode and display NEG 
*---------------------------------------------------------------------------*
OP_NEG      * 0100 0100 xx (size) xxx (ea mode) xxx (ea reg) 
            CLR.L   D1
            CLR.L   D4
            MOVE.L  D5,D1
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            CMPI.B  #0,D1
            BEQ     OP_NEG_B    * size is byte
            CMPI.B  #1,D1
            BEQ     OP_NEG_W    * size is word
            CMPI.B  #2,D1
            BEQ     OP_NEG_L    * size is long
                       
OP_NEG_B    * size is byte   
            MOVE.B  #0,D4 
            LEA     DISP_NEG_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            JSR     EA_NOSRC
            RTS
            
OP_NEG_W    * size is word
            MOVE.B  #1,D4
            LEA     DISP_NEG_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            JSR     EA_NOSRC
            RTS
            
OP_NEG_L    * size is long
            MOVE.B  #2,D4
            LEA     DISP_NEG_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            JSR     EA_NOSRC
            
            RTS

*---------------------------------------------------------------------------*
* OP_NOT: decode and display NOT 
*---------------------------------------------------------------------------*
OP_NOT
            CLR.L   D1
            CLR.L   D4
            MOVE.L  D5,D1
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            CMPI.B  #0,D1
            BEQ     OP_NOT_B    * size is byte
            CMPI.B  #1,D1
            BEQ     OP_NOT_W    * size is word
            CMPI.B  #2,D1
            BEQ     OP_NOT_L    * size is long
                       
OP_NOT_B    * size is byte   
            MOVE.B  #0,D4 
            LEA     DISP_NOT_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_NOT_W    * size is word
            MOVE.B  #1,D4
            LEA     DISP_NOT_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_NOT_L    * size is long
            MOVE.B  #2,D4
            LEA     DISP_NOT_L,A1
            MOVE.B  #14,D0
            TRAP    #15
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
OP_RTS      LEA     DISP_RTS,A1
            MOVE.B  #14,D0
            TRAP    #15
            RTS

*---------------------------------------------------------------------------*
* OP0101: decode ADDQ
*---------------------------------------------------------------------------* 
OP0101      CLR.L   D0               * clear registers for temp storage       
            CLR.L   D1
            CLR.L   D4                  
            MOVEA.L #0, A1  
            
            MOVE.L  D5,D1           * copy the processing data 
            LSR.L   #8,D1           * shift to right by 8 bits to check the value of bit 8
            ANDI.B  #$1,D1          * mask all bits except the last 2 bits
            CMPI.B  #0,D1           * if the value is 0, it's ADDQ
            BEQ     OP_ADDQ
            
            JMP     OP_DATA
     
OP_ADDQ     CLR.L   D1
            MOVE.L  D5,D1
            ROR.L   #6,D1       * shift bit 7,6 to bit 1,0
            ANDI.L  #$3,D1
            CMPI.B  #0,D1
            BEQ     OP_ADDQ_B    * size is byte
            CMPI.W  #1,D1
            BEQ     OP_ADDQ_W    * size is word
            CMPI.L  #2,D1
            BEQ     OP_ADDQ_L    * size is long
            
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
            
OP_BHI		LEA     DISP_BHI,A1          	
            MOVE.B  #14,D0
            TRAP    #15
            RTS

OP_BNE		LEA     DISP_BNE,A1          	
            MOVE.B  #14,D0
            TRAP    #15
            RTS

OP_BEQ		LEA     DISP_BEQ,A1          	
            MOVE.B  #14,D0
            TRAP    #15
            RTS          
            			
OP_BRA		LEA     DISP_BRA,A1          	
            MOVE.B  #14,D0
            TRAP    #15
            RTS
            
OP_BLT		LEA     DISP_BLT,A1          
            MOVE.B  #14,D0
            TRAP    #15
            RTS
   
*---------------------------------------------------------------------------*
* OP0111 : MOVEQ not required
*---------------------------------------------------------------------------*           
OP0111      JMP     OP_DATA
           
*---------------------------------------------------------------------------*
* OP1000 : decode DIVS
*---------------------------------------------------------------------------*           
OP1000      
            CLR.L   D0                
            CLR.L   D1   
            CLR.L   D4                
            MOVEA.L #0, A0               
            MOVEA.L #0, A1               
            
            MOVE.L  D5,D1
            LSR.L   #5,D1
            ANDI.L  #$E,D1
  
            CMPI.B  #$E,D1
            BEQ     OP_DIVS
            
            JMP     OP_DATA

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
OP1001      CLR.L   D0                
            CLR.L   D1   
            CLR.L   D4                 
            MOVEA.L #0, A0                 
            MOVEA.L #0, A1               
            
            MOVE.L  D5,D1
            LSR.L   #5,D1
            ANDI.L  #$E,D1
  
            CMPI.B  #$0,D1
            BEQ     OP_SUB_B
            CMPI.B  #$2,D1
            BEQ     OP_SUB_W
            CMPI.B  #$4,D1
            BEQ     OP_SUB_L
            CMPI.B  #$8,D1
            BEQ     OP_SUB_B
            CMPI.B  #$A,D1
            BEQ     OP_SUB_W
            CMPI.B  #$C,D1
            BEQ     OP_SUB_L
            
            CLR     D1
            MOVE.L  D5,D1
            LSR.L   #6,D1
            ANDI.L  #$F,D1
            CMPI.B  #3,D1
            BEQ     OP_SUBA_W
            CMPI.B  #7,D1
            BEQ     OP_SUBA_L
            
            JMP     OP_DATA
  
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
            BEQ     OP_CMP_B
            CMPI.B  #$2,D1
            BEQ     OP_CMP_W
            CMPI.B  #$4,D1
            BEQ     OP_CMP_L
            CMPI.B  #$8,D1
            BEQ     OP_EOR_B
            CMPI.B  #$A,D1
            BEQ     OP_EOR_W
            CMPI.B  #$C,D1
            BEQ     OP_EOR_L  
            CMPI.B  #$6,D1
            BEQ     OP_CMPA_W
            CMPI.B  #$E,D1
            BEQ     OP_CMPA_L 

            JMP     OP_DATA          

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
            CMPI.W  #$0,D1
            BEQ     OP_AND_B
            CMPI.W  #$2,D1
            BEQ     OP_AND_W
            CMPI.W  #$4,D1
            BEQ     OP_AND_L
            CMPI.W  #$8,D1
            BEQ     OP_AND_B
            CMPI.W  #$A,D1
            BEQ     OP_AND_W
            CMPI.W  #$C,D1
            BEQ     OP_AND_L

            JMP     OP_DATA

OP_MULS     LEA     DISP_MULS_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            JMP     EA_ARITH
            RTS
            
OP_AND_B    
            LEA     DISP_AND_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            RTS

OP_AND_W
            LEA     DISP_AND_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS

OP_AND_L
            LEA     DISP_AND_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS

*---------------------------------------------------------------------------*
* OP1101: Decode ADD/ADDA
*---------------------------------------------------------------------------* 
OP1101      CLR.L   D0                  
            CLR.L   D1       
            CLR.L   D4                   
            MOVEA.L #0, A1              
            MOVE.L  D5,D1
            ROR.L   #5,D1
            ANDI.L  #$E,D1
            CMPI.B  #$0,D1
            BEQ     OP_ADD_B
            CMPI.B  #$2,D1
            BEQ     OP_ADD_W
            CMPI.B  #$4,D1
            BEQ     OP_ADD_L
            CMPI.B  #$8,D1
            BEQ     OP_ADD_B
            CMPI.B  #$A,D1
            BEQ     OP_ADD_W
            CMPI.B  #$C,D1
            BEQ     OP_ADD_L  
            
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
            
            * check for LSX
            ROR.L   #3,D1
            ANDI.L  #$1,D1
            CMPI.B  #1,D1
            BEQ     OP_LSX
            
            * reset D1 and check for ASX
            CLR.L   D1
            MOVE.L  D5,D1
            ROR.L   #3,D1
            ANDI.L  #$1,D1
            CMPI.B  #0,D1
            BEQ     OP_ASX

            * reset D1 and check for ROX
            CLR.L   D1
            MOVE.L  D5,D1
            ROR.L   #3,D1
            ANDI.L  #$1,D1
            CMPI.B  #3,D1
            BEQ     OP_ROX
            
            JMP     OP_DATA

*---------------------------------------------------------------------------*
* OP_LSX: process LSR/LSL
*---------------------------------------------------------------------------*            
OP_LSX      ROR.L   #5,D1
            ANDI.L  #$1,D1
            CMPI.B  #0,D1
            BEQ     OP_LSR
            CMPI.B  #1,D1
            BEQ     OP_LSL
            
*---------------------------------------------------------------------------*
* OP_ASX: process ASR/ASL
*---------------------------------------------------------------------------*  
OP_ASX      ROR.L   #5,D1
            ANDI.L  #$1,D1
            CMPI.B  #0,D1
            BEQ     OP_ASR
            CMPI.B  #1,D1
            BEQ     OP_ASL
            
*---------------------------------------------------------------------------*
* OP_ROX: process ROR/ROL
*---------------------------------------------------------------------------*  
OP_ROX      ROR.L   #5,D1
            ANDI.L  #$1,D1
            CMPI.B  #0,D1
            BEQ     OP_ROR
            CMPI.B  #1,D1
            BEQ     OP_ROL

*---------------------------------------------------------------------------*
* OP_LSR: decode and display LSR
*---------------------------------------------------------------------------*        
OP_LSR      ROL.L   #2,D1
            ANDI.L  #$3,D1
            CMPI.B  #0,D1
            BEQ     OP_LSR_B
            CMPI.B  #$1,D1
            BEQ     OP_LSR_W
            CMPI.B  #$2,D1
            BEQ     OP_LSR_L
            
            JMP     OP_DATA

OP_LSR_B    LEA     DISP_LSR_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            RTS

OP_LSR_L    LEA     DISP_LSR_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS

OP_LSR_W    LEA     DISP_LSR_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS
 
*---------------------------------------------------------------------------*
* OP_LSL: decode and display LSL
*---------------------------------------------------------------------------*             
OP_LSL      ROL.L   #2,D1
            ANDI.L  #$3,D1
            CMPI.B  #0,D1
            BEQ     OP_LSL_B
            CMPI.B  #$1,D1
            BEQ     OP_LSL_W
            CMPI.B  #$2,D1
            BEQ     OP_LSL_L
            
            JMP OP_DATA

OP_LSL_B    LEA     DISP_LSL_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            RTS

OP_LSL_L    LEA     DISP_LSL_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS

OP_LSL_W    LEA     DISP_LSL_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS
 
*---------------------------------------------------------------------------*
* OP_ASR: decode and display ASR
*---------------------------------------------------------------------------*             
OP_ASR      ROL.L   #2,D1
            ANDI.L  #$3,D1
            CMPI.B  #0,D1
            BEQ     OP_ASR_B
            CMPI.B  #$1,D1
            BEQ     OP_ASR_W
            CMPI.B  #$2,D1
            BEQ     OP_ASR_L
            
            JMP OP_DATA

OP_ASR_B    LEA     DISP_ASR_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            RTS

OP_ASR_L    LEA     DISP_ASR_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS

OP_ASR_W    LEA     DISP_ASR_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS
     
*---------------------------------------------------------------------------*
* OP_ASL: decode and display ASL
*---------------------------------------------------------------------------*         
OP_ASL      ROL.L   #2,D1
            ANDI.L  #$3,D1
            CMPI.B  #0,D1
            BEQ     OP_ASL_B
            CMPI.B  #$1,D1
            BEQ     OP_ASL_W
            CMPI.B  #$2,D1
            BEQ     OP_ASL_L
            
            JMP OP_DATA

OP_ASL_B    LEA     DISP_ASL_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            RTS

OP_ASL_L    LEA     DISP_ASL_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS

OP_ASL_W    LEA     DISP_ASL_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS
 
*---------------------------------------------------------------------------*
* OP_ROR: decode and display ROR
*---------------------------------------------------------------------------*             
OP_ROR      ROL.L   #2,D1
            ANDI.L  #$3,D1
            CMPI.B  #0,D1
            BEQ     OP_ROR_B
            CMPI.B  #$1,D1
            BEQ     OP_ROR_W
            CMPI.B  #$2,D1
            BEQ     OP_ROR_L
            
            JMP OP_DATA

OP_ROR_B    LEA     DISP_ROR_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            RTS

OP_ROR_L    LEA     DISP_ROR_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS

OP_ROR_W    LEA     DISP_ROR_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS

*---------------------------------------------------------------------------*
* OP_ROL: decode and display ROL
*---------------------------------------------------------------------------*             
OP_ROL      ROL.L   #2,D1
            ANDI.L  #$3,D1
            CMPI.B  #0,D1
            BEQ     OP_ROL_B
            CMPI.B  #$1,D1
            BEQ     OP_ROL_W
            CMPI.B  #$2,D1
            BEQ     OP_ROL_L
            
            JMP OP_DATA


OP_ROL_B    LEA     DISP_ROL_B,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #0,D4
            RTS

OP_ROL_L    LEA     DISP_ROL_L,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #2,D4
            RTS

OP_ROL_W    LEA     DISP_ROL_W,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.B  #1,D4
            RTS
            
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
DISP_MOVEA_B    DC.B    '   MOVEA.B',0
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


*---------------------------------------------------------------------------*
* Ends program
*---------------------------------------------------------------------------*
            END    START                    * last line of source








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
