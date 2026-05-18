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
module Clock_Divider
#(
    parameter DIVIDER = 25000000
)
(
    input  clk_in,
    input  reset,
    output clk_out
);

reg [31:0] counter;
reg        clk_reg;

always @(posedge clk_in or negedge reset) begin
    if (!reset) begin
        counter <= 0;
        clk_reg <= 0;
    end
    else if (counter >= DIVIDER - 1) begin
        counter <= 0;
        clk_reg <= ~clk_reg;
    end
    else
        counter <= counter + 1;
end

assign clk_out = clk_reg;

endmodule