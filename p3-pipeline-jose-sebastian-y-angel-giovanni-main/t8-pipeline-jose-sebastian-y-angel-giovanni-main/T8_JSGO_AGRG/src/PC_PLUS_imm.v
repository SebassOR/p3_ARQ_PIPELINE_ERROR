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
module Adder_PC_imm (
    input  [31:0] PC_now,
    input  [31:0] Immediate_i,
    output [31:0] Result_o
);

    assign Result_o = PC_now + Immediate_i;

endmodule