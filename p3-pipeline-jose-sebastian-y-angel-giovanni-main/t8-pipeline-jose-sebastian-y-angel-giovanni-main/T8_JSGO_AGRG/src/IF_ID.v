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
module IF_ID(
    input        clk,
    input        reset,
    input        enable,        
    input        flush_branch_i,
    input [31:0] PC_in,
    input [31:0] ins_in,
    input [31:0] pc_plus_4_in,

    output reg [31:0] PC_out,
    output reg [31:0] ins_out,
    output reg [31:0] pc_plus_4_out
);

always @(posedge clk or negedge reset) begin
    if (reset == 1'b0) begin
        PC_out        <= 32'b0;
        ins_out       <= 32'b0;
        pc_plus_4_out <= 32'b0;
    end
    else if (flush_branch_i) begin  
        PC_out        <= 32'b0;
        ins_out       <= 32'b0;
        pc_plus_4_out <= 32'b0;
    end
    else if (enable) begin  
        PC_out        <= PC_in;
        ins_out       <= ins_in;
        pc_plus_4_out <= pc_plus_4_in;
    end
end

endmodule