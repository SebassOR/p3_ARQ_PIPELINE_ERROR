/******************************************************************
* Author:
* José Sebastián González Ortega
* Angel Giovanni Reynoso González
* email:
*  joses.gonzalez@iteso.mx
*	angel.reynoso@iteso.mx
* Date:
*	10/05/2026
******************************************************************/
module Mux_3_to_1
#(
    parameter NBits = 32
)
(
    input  [1:0]          Selector_i,
    input  [NBits-1:0]    Mux_Data_00_i,  
    input  [NBits-1:0]    Mux_Data_01_i,  
    input  [NBits-1:0]    Mux_Data_10_i,  
    output reg [NBits-1:0] Mux_Output_o
);

always @(*) begin
    case (Selector_i)
        2'b00:   Mux_Output_o = Mux_Data_00_i;
        2'b01:   Mux_Output_o = Mux_Data_01_i;
        2'b10:   Mux_Output_o = Mux_Data_10_i;
        default: Mux_Output_o = Mux_Data_00_i;
    endcase
end

endmodule