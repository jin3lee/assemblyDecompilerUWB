*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    
    *constants*
example   EQU       $1234
example1  EQU       $8975
example2  EQU       $3156
example3  EQU       $5555
    
START     ORG       $1000            ; first instruction of program
          MOVE.W    #0,COUNTER
          
          MOVE.W    #example,D0     *loads D0-D3 with data
          MOVE.W    #example1,D1
          MOVE.W    #example2,D2
          MOVE.W    #example3,D3    

          MOVEA.W   SP,A2           *A1 leashes to my stack pointer
          
          MOVE.W    D0,-(A2)        *moves D0-D3 into stack
          MOVE.W    D1,-(A2)
          MOVE.W    D2,-(A2)
          MOVE.W    D3,-(A2)
            
   
      
          *MOVE.W    (A1)+,D4        *moves stuff in stack into D4-D7
          *MOVE.W    (A1)+,D5
          *MOVE.W    (A1)+,D6
          *MOVE.W    (A1)+,D7           
LOOP      ADD.B     #1,COUNTER      *COUNTER 
          CMP.W     #4,COUNTER
          BEQ       END             *CHECK IF LOOP IS FINISHED
          

          MOVE.W   (A2)+,D1           *PRINTS ADDRESS
          MOVE.B   #15,D0             *PRINTS ACCORDING TO D2 BASE VALUE
          MOVE.B   #16,D2             *PRINTS BASED 16 NUMBER
          TRAP        #15             *ACTIVATES PRINT

          TRAP      #15

          BRA       LOOP
          
          
END       MOVE.B  #9,D0
          TRAP    #15          
    
            
SP        DC.B      80
COUNTER   DC.W      1
          END       START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
