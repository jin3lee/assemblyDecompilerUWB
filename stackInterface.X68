*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    
*HOW TO USE STACK 
SP        EQU       $7000
    
START     ORG       $1000            ; first instruction of program
          MOVE.W    #0,COUNTER
          MOVEA.W   #SP,A2           *A1 leashes to my stack pointer
          
          MOVE.W    #$3344,D3
          BSR       PUSH_STACK
          MOVE.W    #$7700,D3
          BSR       PUSH_STACK
          MOVE.W    #$2222,D3
          BSR       PUSH_STACK 
          
          BSR       CLEAR_STACK
          
          MOVE.W    #$3344,D3
          BSR       PUSH_STACK
          MOVE.W    #$7700,D3
          BSR       PUSH_STACK
          MOVE.W    #$2222,D3
          BSR       PUSH_STACK 
          
          BSR       PRINT_STACK
          BRA       END         
            
   
PRINT_STACK
          CMP.B     #0,COUNTER
          BEQ       END             *CHECK IF LOOP IS FINISHED
          
PRINT_STACK_HELPER
          BSR      POP_STACK          *PRINTS ADDRESS
          MOVE.B   #15,D0             *PRINTS ACCORDING TO D2 BASE VALUE
          MOVE.B   #16,D2             *PRINTS BASED 16 NUMBER
          TRAP        #15             *ACTIVATES PRINT

          LEA       MSG_SPACE,A1      * PRINTS " " AFTER EACH POP
          MOVE.B    #14, D0  
          TRAP      #15

          BRA       PRINT_STACK
          
          RTS
          
*PUSHES.W CONTENTS OF [D3] INTO STACK          
PUSH_STACK
            MOVE.W  D3,-(A2)
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
            MOVE.W  (A2)+,D1 
            BSR     DECREMENT
POP_RETURN
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
END       
            LEA     MSG,A1
            MOVE.B  #14,D0
            TRAP    #15
            
            MOVE.B  #9,D0
            TRAP    #15          
    
            
MSG_SPACE   DC.B    ' ',0            
MSG       DC.B      'END',0   
COUNTER   DC.W      1
          END       START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
