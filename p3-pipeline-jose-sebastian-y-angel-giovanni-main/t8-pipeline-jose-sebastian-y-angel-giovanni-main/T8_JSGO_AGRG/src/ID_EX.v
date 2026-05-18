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
module ID_EX (
    input clk,
    input reset,
    input flush_i,              
    input [31:0] PC_in,
    input [31:0] Rd1_in,
    input [31:0] Rd2_in,
    input [31:0] Imm_in,
    input [31:0] Ins_in,
    input [4:0]  Rd_addr_in,
    input [31:0] pc_plus_4_in,
     
    // Control WB
    input reg_write_in,
    input mem_to_reg_in,
     
    // Control MEM
    input mem_read_in,
    input mem_write_in,
    input branch_in,
    input jal_ID,
    input jalr_ID,
     
     
    // Control EX
    input alu_src_in,
    input [2:0] alu_op_in,
    input auipc_in,
     
     
    // Salidas datos
    output reg [31:0] PC_out,
    output reg [31:0] Rd1_out,
    output reg [31:0] Rd2_out,
    output reg [31:0] Imm_out,
    output reg [4:0]  Rd_addr_out,
    output reg [31:0] Ins_out,
    output reg [31:0] pc_plus_4_out,

    // Control WB
    output reg reg_write_out,
    output reg mem_to_reg_out,
    // Control MEM
     
    output reg mem_read_out,
    output reg mem_write_out,
    output reg branch_out,
    output reg jal_EX,
    output reg jalr_EX,
     
     
    // Control EX
    output reg alu_src_out,
    output reg [2:0] alu_op_out,
    output reg auipc_out
);

always @(posedge clk or negedge reset) begin
    if (reset == 1'b0) begin
        PC_out         <= 32'b0;
        Rd1_out        <= 32'b0;
        Rd2_out        <= 32'b0;
        Imm_out        <= 32'b0;
        Ins_out        <= 32'b0;
        Rd_addr_out    <= 5'b0;
        pc_plus_4_out  <= 32'b0;
        auipc_out      <= 1'b0;
        reg_write_out  <= 1'b0;
        mem_to_reg_out <= 1'b0;
        mem_read_out   <= 1'b0;
        mem_write_out  <= 1'b0;
        branch_out     <= 1'b0;
        jal_EX         <= 1'b0;
        jalr_EX        <= 1'b0;
        alu_src_out    <= 1'b0;
        alu_op_out     <= 3'b0;
    end else begin
        //Datos siempre pasan 
        PC_out        <= PC_in;
        Rd1_out       <= Rd1_in;
        Rd2_out       <= Rd2_in;
        Imm_out       <= Imm_in;
        Rd_addr_out   <= Rd_addr_in;
        Ins_out       <= Ins_in;
        pc_plus_4_out <= pc_plus_4_in;
        auipc_out     <= auipc_in;

        //flush para los nops
        reg_write_out  <= flush_i ? 1'b0 : reg_write_in;
        mem_to_reg_out <= flush_i ? 1'b0 : mem_to_reg_in;
        mem_read_out   <= flush_i ? 1'b0 : mem_read_in;
        mem_write_out  <= flush_i ? 1'b0 : mem_write_in;
        branch_out     <= flush_i ? 1'b0 : branch_in;
        jal_EX         <= flush_i ? 1'b0 : jal_ID;
        jalr_EX        <= flush_i ? 1'b0 : jalr_ID;
        alu_src_out    <= flush_i ? 1'b0 : alu_src_in;
        alu_op_out     <= flush_i ? 3'b0 : alu_op_in;
    end
end

endmodule