
/******************************************************************
* Author:
* José Sebastián González Ortega
* Angel Giovanni Reynoso González
* email:
*  joses.gonzalez@iteso.mx
*	angel.reynoso@iteso.mx
* Date:
*	29/03/2026
******************************************************************/
module AND_CONTROL (
    output PCscr,
    input  Branch_i,
    input  ALU_zero_i,
    input  JAL_i,
    input  JALR_i,
    input  [2:0] funct3_i
);

wire beq_w = (funct3_i == 3'b000);
wire bne_w = (funct3_i == 3'b001);
wire bge_w = (funct3_i == 3'b101);

assign PCscr = (Branch_i & ((beq_w &  ALU_zero_i)  |  (bne_w & ~ALU_zero_i)  |  (bge_w &  ALU_zero_i)    )) | JAL_i | JALR_i; 

endmodule
