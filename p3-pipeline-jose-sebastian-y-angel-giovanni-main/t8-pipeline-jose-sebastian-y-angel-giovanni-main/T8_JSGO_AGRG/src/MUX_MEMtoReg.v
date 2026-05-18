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
module MUX_MEMtoReg (
    input         mem2reg,
    input  [31:0] mem_i,
    input  [31:0] ALU_i,
    output [31:0] MUX_ALU_o
);

    assign MUX_ALU_o = mem2reg ? mem_i : ALU_i;

endmodule 