/******************************************************************
* Author:
* José Sebastián González Ortega
* Angel Giovanni Reynoso González
* email:
*  joses.gonzalez@iteso.mx
*	angel.reynoso@iteso.mx
* Date:
*	26/04/2026
******************************************************************/
module EX_MEM (
    input clk,
    input reset,

    //info
    input [31:0] PC_plus_imm_in,   
    input [31:0] ALU_result_in,    
    input [31:0] Rs2_in,          
    input [4:0]  Rd_addr_in,      
    input [31:0] pc_plus_4_in,

    //Control WB
    input reg_write_in,
    input mem_to_reg_in,
     
    input  [2:0] funct3_in,
    output reg [2:0] funct3_out,

    //Control MEM 
    input mem_read_in,
    input mem_write_in,
    input branch_in,
    input jal_in,
    input jalr_in,
    input zero_in,                 

    //SALIDAS
    output reg [31:0] PC_plus_imm_out,
    output reg [31:0] ALU_result_out,
    output reg [31:0] Rs2_out,
    output reg [4:0]  Rd_addr_out,
    output reg [31:0] pc_plus_4_out,

    //Control WB
    output reg reg_write_out,
    output reg mem_to_reg_out,

    //Control MEM
    output reg mem_read_out,
    output reg mem_write_out,
    output reg branch_out,
    output reg jal_out,
    output reg jalr_out,
    output reg zero_out   
);

always @(posedge clk or negedge reset) begin
        if (reset == 1'b0) begin
            PC_plus_imm_out <= 32'b0;
            ALU_result_out  <= 32'b0;
            Rs2_out         <= 32'b0;
            Rd_addr_out     <= 5'b0;
            pc_plus_4_out   <= 32'b0;
            funct3_out      <= 3'b0;
            reg_write_out   <= 1'b0;
            mem_to_reg_out  <= 1'b0;
            mem_read_out    <= 1'b0;
            mem_write_out   <= 1'b0;
            branch_out      <= 1'b0;
            jal_out         <= 1'b0;
            jalr_out        <= 1'b0;
            zero_out        <= 1'b0;
        end else begin
            PC_plus_imm_out <= PC_plus_imm_in;
            ALU_result_out  <= ALU_result_in;
            Rs2_out         <= Rs2_in;
            Rd_addr_out     <= Rd_addr_in;
            pc_plus_4_out   <= pc_plus_4_in;
            funct3_out      <= funct3_in;
            reg_write_out   <= reg_write_in;
            mem_to_reg_out  <= mem_to_reg_in;
            mem_read_out    <= mem_read_in;
            mem_write_out   <= mem_write_in;
            branch_out      <= branch_in;
            jal_out         <= jal_in;
            jalr_out        <= jalr_in;
            zero_out        <= zero_in;
        end
    end

endmodule