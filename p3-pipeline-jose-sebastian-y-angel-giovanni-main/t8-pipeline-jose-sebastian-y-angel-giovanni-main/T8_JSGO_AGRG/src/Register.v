/******************************************************************
* Description
*	This the basic register that is used in the register file
*	1.0
* Author:
*	Dr. José Luis Pizano Escalante
* email:
*	luispizano@iteso.mx
* Date:
*	16/08/2021
******************************************************************/
module Register
#(
    parameter N = 32,
    parameter RESET_VALUE = 32'h00000000 //para el sp
)
(
    input clk,
    input reset,
    input enable,
    input  [N-1:0] DataInput,
    output reg [N-1:0] DataOutput
);

always @(posedge clk or negedge reset) begin
    if (!reset)                    
        DataOutput <= RESET_VALUE;
    else if (enable)
        DataOutput <= DataInput;
end

endmodule