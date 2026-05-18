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
module Mux_PC (
    input  [31:0] pc_plus_4,
    input  [31:0] PCplus_imm,
    input         PCscr,
    output [31:0] new_PC
);

    assign new_PC = PCscr ? PCplus_imm : pc_plus_4;

endmodule