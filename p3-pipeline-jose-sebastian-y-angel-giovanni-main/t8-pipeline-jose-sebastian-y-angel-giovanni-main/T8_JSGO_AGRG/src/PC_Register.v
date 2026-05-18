/******************************************************************
* Description
*	This is a register of 32-bit that corresponds to the PC counter. 
*	This register does not have an enable signal.
* Version:
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	16/08/2021
******************************************************************/

module PC_Register
#(
    parameter N=32
)
(
    input clk,
    input reset,
    input         enable,       
    input  [N-1:0] Next_PC,
    output reg [N-1:0] PC_Value
);

always @(posedge clk or negedge reset) begin
    if (!reset)
        PC_Value <= 32'h00400000;
    else if (enable)            
        PC_Value <= Next_PC;
end

endmodule
