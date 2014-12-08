*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
  ORG    $6000
START   


**************************************************************************************************************MOVE.B*
            MOVE.B  D1,D1
            MOVE.B  D2,(A2)
            MOVE.B  D3,(A3)+
            MOVE.B  D4,-(A4)
            MOVE.B  D5,$3333
            MOVE.B  D6,$44444444
            
            *MOVE.B  A1,D1           *NOT ALLOWED FOR BYTE SIZE OPERATION (CAN'T RUN THIS)
            *MOVE.B  A2,(A2)
            *MOVE.B  A3,(A3)+
            *MOVE.B  A4,-(A4)
            *MOVE.B  A5,$3333
            *MOVE.B  A6,$44444444
            
            MOVE.B  (A1),D1
            MOVE.B  (A2),(A2)
            MOVE.B  (A3),(A3)+
            MOVE.B  (A4),-(A4)
            MOVE.B  (A5),$3333
            MOVE.B  (A6),$44444444
             
            MOVE.B  (A1)+,D1
            MOVE.B  (A2)+,(A2)
            MOVE.B  (A3)+,(A3)+
            MOVE.B  (A4)+,-(A4)
            MOVE.B  (A5)+,$3333
            MOVE.B  (A6)+,$44444444

            MOVE.B  -(A1),D1
            MOVE.B  -(A2),(A2)
            MOVE.B  -(A3),(A3)+
            MOVE.B  -(A4),-(A4)
            MOVE.B  -(A5),$3333
            MOVE.B  -(A6),$44444444
            
            MOVE.B  $3331,D1
            MOVE.B  $3332,(A2)
            MOVE.B  $3333,(A3)+
            MOVE.B  $3334,-(A4)
            MOVE.B  $3335,$3333
            MOVE.B  $3336,$44444444
            
            MOVE.B  $44444441 ,D1
            MOVE.B  $44444442 ,(A2)
            MOVE.B  $44444443 ,(A3)+
            MOVE.B  $44444444 ,-(A4)
            MOVE.B  $44444445 ,$3333
            MOVE.B  $44444446 ,$44444444 

**************************************************************************************************************MOVE.W*
            MOVE.W  D1,D1
            MOVE.W  D2,(A2)
            MOVE.W  D3,(A3)+
            MOVE.W  D4,-(A4)
            MOVE.W  D5,$3333
            MOVE.W  D6,$44444444
            
            *MOVE.B  A1,D1           *NOT ALLOWED FOR BYTE SIZE OPERATION (CAN'T RUN THIS)
            *MOVE.B  A2,(A2)
            *MOVE.B  A3,(A3)+
            *MOVE.B  A4,-(A4)
            *MOVE.B  A5,$3333
            *MOVE.B  A6,$44444444
            
            MOVE.W  (A1),D1
            MOVE.W  (A2),(A2)
            MOVE.W  (A3),(A3)+
            MOVE.W  (A4),-(A4)
            MOVE.W  (A5),$3333
            MOVE.W  (A6),$44444444
             
            MOVE.W  (A1)+,D1
            MOVE.W  (A2)+,(A2)
            MOVE.W  (A3)+,(A3)+
            MOVE.W  (A4)+,-(A4)
            MOVE.W  (A5)+,$3333
            MOVE.W  (A6)+,$44444444

            MOVE.W  -(A1),D1
            MOVE.W  -(A2),(A2)
            MOVE.W  -(A3),(A3)+
            MOVE.W  -(A4),-(A4)
            MOVE.W  -(A5),$3333
            MOVE.W  -(A6),$44444444
            
            MOVE.W  $3331,D1
            MOVE.W  $3332,(A2)
            MOVE.W  $3333,(A3)+
            MOVE.W  $3334,-(A4)
            MOVE.W  $3335,$3333
            MOVE.W  $3336,$44444444
            
            MOVE.W  $44444441 ,D1
            MOVE.W  $44444442 ,(A2)
            MOVE.W  $44444443 ,(A3)+
            MOVE.W  $44444444 ,-(A4)
            MOVE.W  $44444445 ,$3333
            MOVE.W  $44444446 ,$44444444 
            
            
            
**************************************************************************************************************MOVE.L*
            MOVE.L  D1,D1
            MOVE.L  D2,(A2)
            MOVE.L  D3,(A3)+
            MOVE.L  D4,-(A4)
            MOVE.L  D5,$3333
            MOVE.L  D6,$44444444
           
            *MOVE.B  A1,D1           *NOT ALLOWED FOR BYTE SIZE OPERATION (CAN'T RUN THIS)
            *MOVE.B  A2,(A2)
            *MOVE.B  A3,(A3)+
            *MOVE.B  A4,-(A4)
            *MOVE.B  A5,$3333
            *MOVE.B  A6,$44444444
            
            MOVE.L  (A1),D1
            MOVE.L  (A2),(A2)
            MOVE.L  (A3),(A3)+
            MOVE.L  (A4),-(A4)
            MOVE.L  (A5),$3333
            MOVE.L  (A6),$44444444
             
            MOVE.L  (A1)+,D1
            MOVE.L  (A2)+,(A2)
            MOVE.L  (A3)+,(A3)+
            MOVE.L  (A4)+,-(A4)
            MOVE.L  (A5)+,$3333
            MOVE.L  (A6)+,$44444444

            MOVE.L  -(A1),D1
            MOVE.L  -(A2),(A2)
            MOVE.L  -(A3),(A3)+
            MOVE.L  -(A4),-(A4)
            MOVE.L  -(A5),$3333
            MOVE.L  -(A6),$44444444
            
            MOVE.L  $3331,D1
            MOVE.L  $3332,(A2)
            MOVE.L  $3333,(A3)+
            MOVE.L  $3334,-(A4)
            MOVE.L  $3335,$3333
            MOVE.L  $3336,$44444444
            
            MOVE.L  $44444441 ,D1
            MOVE.L  $44444442 ,(A2)
            MOVE.L  $44444443 ,(A3)+
            MOVE.L  $44444444 ,-(A4)
            MOVE.L  $44444445 ,$3333
            MOVE.L  $44444446 ,$44444444 
            
            
                        
**************************************************************************************************************MOVEA.L*
              MOVEA.L  D1,A1
            MOVEA.L  A2,A2   
            MOVEA.L  (A3),A3
            MOVEA.L  (A4)+,A4
            MOVEA.L  -(A5),A5
            MOVEA.L  $3331,A6
            MOVEA.L  $44444441,A7
                                    
**************************************************************************************************************MOVEA.W*
            MOVEA.W  D1,A1
            MOVEA.W  A2,A2   
            MOVEA.W  (A3),A3
            MOVEA.W  (A4)+,A4
            MOVEA.W  -(A5),A5
            MOVEA.W  $3331,A6
            MOVEA.W  $44444441,A7
            
            
            
            
    MOVE.B  #9,D0
    TRAP    #15
    END    START        





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
